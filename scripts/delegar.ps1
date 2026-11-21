[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('analista-requisitos', 'arquiteto', 'criador-tarefas', 'desenvolvedor', 'revisor-codigo', 'qa')]
    [string] $Papel,

    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]*$')]
    [string] $Feature,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Handoff
)

$preferenciaErroOriginal = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $raiz 'src/9router.json') | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($config.modelo) -or $config.base_url -notmatch '^https?://[^\s]+$') {
    throw 'Preencha modelo e base_url em src/9router.json.'
}

if (!$Feature -and $Papel -ne 'analista-requisitos') {
    throw 'Informe -Feature com o nome do diretorio da especificacao aprovada.'
}
if ($Feature) {
    $estado = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $raiz "specs/$Feature/state.json") | ConvertFrom-Json
    $branch = git -C $raiz branch --show-current
    if ($LASTEXITCODE -ne 0 -or !$branch -or $estado.feature -cne $Feature -or
        $estado.branch -cne $branch -or $branch -ceq $estado.base_branch) {
        throw 'O estado e a branch atual precisam corresponder a feature indicada.'
    }
    if ($Papel -ne 'analista-requisitos') {
        $aprovacao = $estado.human_checkpoints.specification_review
        $etapasAtivas = @('PLANEJANDO', 'CRIANDO_TAREFAS', 'ANALISANDO', 'IMPLEMENTANDO', 'REVISANDO', 'TESTANDO', 'PUBLICANDO_PR')
        if ($aprovacao.status -cne 'aprovado' -or [string]::IsNullOrWhiteSpace($aprovacao.mensagem) -or
            $estado.stage -cnotin $etapasAtivas) {
            throw 'A delegacao exige aprovacao humana registrada e uma etapa em andamento depois do Checkpoint 1.'
        }
    }
}

$cli = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (!$cli) {
    throw 'Codex CLI ausente no PATH do VS Code. O comando necessario para os especialistas e codex exec.'
}
$instrucoes = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $raiz "src/subagent-$Papel.md")
$mensagem = "Papel delegado: $Papel`n`n$instrucoes`n`n## Handoff do orquestrador`n$Handoff"
$opcoes = @(
    'exec', '--ephemeral', '--cd', $raiz, '--model', $config.modelo,
    '-c', "default_permissions=fabrica-$Papel",
    '-c', 'approval_policy=never',
    '-c', 'features.multi_agent=false',
    '-c', 'features.multi_agent_v2=false',
    '-c', 'model_reasoning_effort=medium',
    '-c', 'model_provider=fabrica_9router',
    '-c', 'model_providers.fabrica_9router.name=9Router',
    '-c', "model_providers.fabrica_9router.base_url=$($config.base_url)",
    '-c', 'model_providers.fabrica_9router.wire_api=responses',
    '-c', 'model_providers.fabrica_9router.requires_openai_auth=false',
    '-c', 'model_providers.fabrica_9router.env_key=FABRICA_9ROUTER_API_KEY',
    '-'
)

# O modo local do 9Router aceita um valor de teste quando a chave esta desativada.
$chaveOriginal = $env:FABRICA_9ROUTER_API_KEY
$codificacaoOriginal = $OutputEncoding
$log = [System.IO.Path]::GetTempFileName()
$preservarLog = $false
try {
    if ([string]::IsNullOrWhiteSpace($chaveOriginal)) {
        $env:FABRICA_9ROUTER_API_KEY = 'local-sem-chave'
    }
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    # O CLI envia o progresso para stderr e o resultado final para stdout.
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = $null
    $mensagem | & $cli.Source @opcoes 2> $log
    $codigo = $global:LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($null -eq $codigo -or $codigo -ne 0) {
        # ReadAllText reconhece o BOM do redirecionamento no Windows PowerShell 5.1.
        $conteudoLog = [System.IO.File]::ReadAllText($log)
        if ($env:FABRICA_9ROUTER_API_KEY) {
            $conteudoLog = $conteudoLog.Replace($env:FABRICA_9ROUTER_API_KEY, '[chave omitida]')
        }
        $conteudoLog = [regex]::Replace($conteudoLog, '(?i)\bBearer\s+[^\s"''<>]+', 'Bearer [chave omitida]')
        $conteudoLog = [regex]::Replace($conteudoLog, '\b(?:sk-[A-Za-z0-9_-]{8,}|nvapi-[A-Za-z0-9_-]{8,}|github_pat_[A-Za-z0-9_]+|gh[pousr]_[A-Za-z0-9]+)\b', '[chave omitida]')
        [System.IO.File]::WriteAllText($log, $conteudoLog, [System.Text.UTF8Encoding]::new($false))
        $preservarLog = $true
        $detalhe = ($conteudoLog -split '\r?\n' | Select-Object -Last 40) -join [Environment]::NewLine
        if ($conteudoLog -match '(?i)\b429\b|free-models-per-day|quota.{0,24}exceed|rate.limit.{0,24}exceed') {
            $orientacao = 'Ha indicacao de limite/cota no log. Aguarde a renovacao informada pelo provedor antes de repetir. Modelos gratuitos podem compartilhar a mesma cota; trocar de modelo nao necessariamente a renova.'
        } else {
            $orientacao = 'O erro final de um combo pode ocultar falhas de outros destinos, incluindo cota, ferramentas ou autenticacao. Confira os registros do roteador; um HTTP 410 isolado nao identifica todas as causas.'
        }
        $codigoExibido = if ($null -eq $codigo) { 'nao informado pelo processo' } else { $codigo }
        throw "Falha na chamada ao 9Router (codex exec, codigo $codigoExibido). $orientacao`nLog completo do CLI, sanitizado e fora do repositorio: $log`nUltimas linhas:`n$detalhe"
    }
}
finally {
    $env:FABRICA_9ROUTER_API_KEY = $chaveOriginal
    $OutputEncoding = $codificacaoOriginal
    $ErrorActionPreference = $preferenciaErroOriginal
    if (!$preservarLog) {
        Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
    }
}
