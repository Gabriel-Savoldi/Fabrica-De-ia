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
$log = [System.IO.Path]::GetTempFileName()
try {
    if ([string]::IsNullOrWhiteSpace($chaveOriginal)) {
        $env:FABRICA_9ROUTER_API_KEY = 'local-sem-chave'
    }
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    # O CLI envia o progresso para stderr e o resultado final para stdout.
    $ErrorActionPreference = 'Continue'
    $mensagem | & $cli.Source @opcoes 2> $log
    $codigo = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($codigo -ne 0) {
        $detalhe = (Get-Content -LiteralPath $log -Tail 6) -join [Environment]::NewLine
        if ($chaveOriginal) {
            $detalhe = $detalhe.Replace($chaveOriginal, '[chave omitida]')
        }
        throw "Falha na chamada ao 9Router (codex exec, codigo $codigo). $detalhe"
    }
}
finally {
    $env:FABRICA_9ROUTER_API_KEY = $chaveOriginal
    Remove-Item -LiteralPath $log
}
