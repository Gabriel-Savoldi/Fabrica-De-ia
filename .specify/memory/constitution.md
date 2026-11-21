# Fábrica de Software Agêntica Constitution

**Situação:** aprovada e ratificada em 2026-11-21.

Esta constituição consolida as regras de `AGENTS.md`, `readme.md`,
`src/orquestrador.md` e dos seis arquivos `src/subagent-*.md`. Sua ratificação não
inicia uma feature nem autoriza a execução das etapas da fábrica.

## Core Principles

### I. Controle humano e escopo autorizado

O pedido do humano delimita a execução. Pedidos de explicação, preparação ou edição
de material são atendidos diretamente; uma etapa da fábrica só começa quando o
pedido abranger sua execução. Os agentes não inventam requisitos nem alteram o
escopo aprovado por decisão técnica.

O Checkpoint 1 exige que o orquestrador apresente a `spec.md` e encerre o turno para
revisão. A aprovação só vale por mensagem explícita do humano no chat, posterior à
apresentação, registrada com data e trecho literal em
`state.json.human_checkpoints.specification_review`. Commit, permissão de terminal
e conclusão do Analista não substituem essa aprovação. Antes de E2, o orquestrador
cita o trecho aprovado. Se houver pedido de pausa, registra
`ESPECIFICACAO_APROVADA` e aguarda o pedido de retomada, sem exigir nova aprovação.

Mudança de requisito ou escopo passa pelo Analista com `speckit-clarify`, deixa
registro em `## Clarifications` e torna o Checkpoint 1 pendente novamente. No
Checkpoint 2, só o humano faz o merge do PR na branch base; a fábrica registra
`ENTREGUE` apenas depois de confirmar o merge no GitHub.

**Razão:** preservar a decisão humana sobre o que será construído e incorporado à base.

### II. Orquestração única e responsabilidades delimitadas

O chat local do Codex no VS Code é o único dono do fluxo. Ele prepara a branch,
delega, valida o escopo e os resultados, escreve `state.json` e conduz as operações
de escrita no Git e o uso de `gh` previstos no fluxo. Ele não implementa o produto.

Os seis especialistas são acionados pelo orquestrador por `scripts/delegar.ps1`,
com o provedor e o combo configurados em `src/9router.json`. Há somente um
especialista em execução por vez; o próximo só é acionado após a validação da etapa
anterior. Indisponibilidade do roteador é um bloqueio, não autorização para trocar
silenciosamente o mecanismo de delegação.

Cada especialista lê o papel e o handoff, trabalha apenas no escopo recebido e
devolve o bloco de status. Especialistas não acionam outros papéis, não fazem
operações de escrita no Git, não usam `gh`, não escrevem `state.json` e não envolvem
o humano diretamente. Revisor não corrige código; QA não corrige produção;
Desenvolvedor não altera testes de aceite de responsabilidade do QA.

**Razão:** manter um responsável pelo andamento e uma responsabilidade identificável
para cada artefato, correção e decisão.

### III. Spec Kit como fonte de verdade

Os artefatos são gerados e atualizados pelas skills `speckit-*` instaladas em
`.agents/skills/`, com os scripts existentes e o template resolvido pela skill.
Seções obrigatórias, identificadores e todos os arquivos gerados são preservados;
é proibido apagá-los, renomeá-los, movê-los, mesclá-los ou substituí-los por formatos
próprios e documentos paralelos de mesma função.

Uma `spec.md` existente só é alterada por `speckit-clarify`, executado pelo Analista;
ela nunca é editada manualmente, inclusive quando a mudança foi pedida pelo humano.
Esclarecimentos ficam na própria spec. O Desenvolvedor só altera as marcações de
conclusão em `tasks.md`; não redefine requisitos, tarefas ou decisões do plano.

A sequência obrigatória é `speckit-specify`, `speckit-clarify` quando necessário,
`speckit-plan`, `speckit-tasks`, `speckit-analyze` e `speckit-implement`.
`speckit-checklist` é complementar. Etapa ou skill indisponível gera bloqueio; não
se pula a etapa nem se reproduz seu trabalho manualmente.

**Razão:** manter requisitos, decisões e execução em documentos compatíveis e verificáveis.

### IV. Rastreabilidade e continuidade do trabalho

Cada feature mantém a ligação entre requisitos `FR-xxx`, critérios mensuráveis
`SC-xxx`, histórias `USn`, tarefas `Txxx`, código e testes. Toda história tem tarefas
identificadas e todo requisito funcional tem cobertura de tarefa. O relatório de
QA relaciona casos de teste, requisitos, critérios de sucesso e histórias; o PR
reúne a spec, resultados de verificação, pareceres, premissas, pendências e riscos.

Cada spec tem uma branch com o mesmo nome do diretório `specs/<feature>/`.
Antes e depois de cada delegação sobre uma feature existente, o orquestrador
confere a branch; o especialista também a confere antes de trabalhar. A feature
selecionada pelos scripts, via `SPECIFY_FEATURE_DIRECTORY` ou
`.specify/feature.json`, deve corresponder ao diretório e à branch informados no
handoff. Na abertura de E1, a spec é gerada na base registrada e o orquestrador
prepara a branch da feature após a geração do diretório.

Só o orquestrador mantém `state.json`: etapa, artefatos, comandos, tarefas
concluídas, checkpoints, decisões técnicas com seus responsáveis, bloqueios,
contadores e data de atualização. O estado é atualizado a cada etapa, fase e
rodada. A retomada começa pela primeira etapa pendente, sem refazer etapas
concluídas fora das devoluções previstas ou de autorização humana.

Todo handoff contém feature e branch, etapa e skill, entradas, decisões
ratificadas, pendências a registrar, limite de escopo, local das notas, comandos
de verificação, fase ou apontamentos específicos e formato de retorno. O retorno
informa `STATUS`, `ARTEFATOS`, `TESTES`, `BLOQUEIOS` e `PRÓXIMO`; Revisor e QA
incluem `PARECER` quando a avaliação foi executada.

Anotações de processo usam o artefato apropriado ou o retorno. Quando precisarem
de arquivo, ficam em `specs/<feature>/notes/`, com nome em kebab-case prefixado
pela etapa. Arquivo de controle na raiz reprova a entrega.

**Razão:** permitir auditoria e retomada sem depender da memória de uma conversa.

### V. Entregas verificadas por evidências

Declaração de conclusão não comprova entrega. O orquestrador lê os arquivos no
disco, compara-os com `ARTEFATOS`, verifica as alterações e exige o critério de
avanço da etapa. Antes e depois de cada delegação, registra e confere branch,
HEAD e estado do diretório para identificar alterações fora do escopo.

O Arquiteto declara em `plan.md` o comando de teste obrigatório e os comandos de
lint e build/typecheck quando existirem; o orquestrador os registra em
`state.json.commands`. Plano sem comando de teste não passa. Desenvolvedor e
orquestrador executam os comandos de verificação; o orquestrador não substitui sua
execução pelo relato do especialista. Todos os comandos aplicáveis devem sair
com código `0`, com comando e resultado registrados.

O Desenvolvedor escreve testes unitários para o código implementado e testes de
integração quando houver integração entre módulos ou serviços externos, mesmo
sem tarefa específica de teste. O QA cria e executa testes de aceite de acordo
com a spec, executa a suíte existente e registra comandos, códigos de saída e
totais de aprovados e reprovados. QA sem execução real retorna `BLOCKED` e não
emite parecer. Testes criados ou alterados pelo QA passam pelo Revisor antes de E7.

Na revisão, achado Crítico ou violação da constituição sem justificativa em
`Complexity Tracking` bloqueia a entrega. Os demais achados permitem aprovação
com ressalvas. No QA, defeito Crítico ou Alto, ou qualquer teste falhando,
bloqueia a entrega. Ressalvas não bloqueantes são registradas no PR.

**Razão:** comprovar tanto a realização do trabalho quanto o atendimento à especificação.

### VI. Autonomia técnica com correções limitadas

Após o Checkpoint 1 e respeitado eventual pedido de pausa, E2 a E7 seguem sem
novas confirmações de passos intermediários. O especialista responsável resolve
dúvidas técnicas com decisão fundamentada, registrada no artefato apropriado;
lacuna de requisito volta ao humano pelo orquestrador e reabre o Checkpoint 1.

Artefatos inconsistentes voltam ao seu responsável. Correções de produção
solicitadas pelo Revisor, QA, CI ou sincronização com a base voltam ao
Desenvolvedor na mesma branch e repetem validação, revisão e aceite. Teste de QA
contestado volta ao QA, com justificativa, sem ser alterado pelo Desenvolvedor.

Há no máximo duas devoluções por etapa; uma terceira necessidade de devolução
gera `BLOCKED` e escalonamento ao humano. Cada devolução conta na etapa que
reprovou, mesmo quando a correção percorre outras etapas. Há também o limite
global de cinco rodadas de correção após E4, somando Revisor, QA, CI e
sincronização; atingido o limite, o orquestrador registra `BLOCKED` e apresenta
o histórico. Rodadas pedidas pelo humano no Checkpoint 2 não consomem esse limite.

Além dos checkpoints, o humano só é envolvido por constituição ausente ou
incompleta, mudança de requisito ou escopo, limites esgotados ou impedimento que
exija acesso, credencial ou ferramenta indisponível à fábrica. Cancelamento
pedido pelo humano é registrado como `CANCELADA`, preservando branch e PR salvo
pedido explícito para removê-los ou fechá-los.

**Razão:** permitir progresso autônomo sem ciclos ilimitados nem mudanças silenciosas de escopo.

### VII. Segurança e integridade do repositório

Segredos vêm de variáveis de ambiente; valores reais não são gravados no chat,
código, testes ou arquivos versionados. `.env` fica no `.gitignore` e
`.env.example` contém apenas exemplos sem segredos. O orquestrador confere os
arquivos preparados para cada commit e impede a inclusão de credenciais.

Testes usam dados, variáveis, mocks, stubs e serviços de teste definidos no plano.
Não há testes destrutivos em ambientes reais nem migrações contra bancos fora
do ambiente local ou de teste. Alterações de schema exigem migrações versionadas
e reversíveis. Dependência fora do plano exige justificativa do Desenvolvedor,
avaliação do Revisor e registro no PR.

Uma feature nova exige árvore de trabalho limpa, base com commit, remoto `origin`
e `gh` autenticado. O orquestrador não inicializa repositório nem configura remotos
por conta própria. Há uma feature em andamento por diretório de trabalho;
execução paralela de features exige worktrees separados preparados pelo humano.

Commits da feature ocorrem na sua branch, nunca na base. A sincronização da base
na branch da feature é a única operação de merge permitida ao orquestrador.
Merge do PR na base, auto-merge, force push, rebase, reset destrutivo e deploy são
proibidos à fábrica.

**Razão:** proteger credenciais, ambientes e o trabalho existente durante a execução autônoma.

## Responsabilidades e limites dos papéis

| Papel | Responsabilidade e entregas | Limite de atuação |
| --- | --- | --- |
| Humano | Define a demanda, responde dúvidas de requisito, aprova a spec e faz o merge do PR. | A aprovação da spec e a decisão de merge não são delegadas à fábrica. |
| Orquestrador | Prepara a branch, monta handoffs, delega em sequência, executa `speckit-analyze`, confere artefatos e comandos, mantém `state.json`, commits, push, PR e CI. | Não implementa produto nem edita manualmente artefatos do Spec Kit durante a feature. |
| Analista de Requisitos | Usa `speckit-specify`, `speckit-clarify` e, quando solicitado, `speckit-checklist`; entrega spec e checklists. | Não define solução técnica; devolve perguntas ou `HUMAN_REVIEW_REQUIRED`, nunca encaminha ao Arquiteto. |
| Arquiteto | Usa `speckit-plan`; entrega `plan.md`, `research.md`, `quickstart.md`, comandos de verificação e, quando aplicáveis, `data-model.md` e `contracts/`. | Não implementa nem cria tarefas; atualização de `AGENTS.md` fica no bloco gerenciado pela integração, preservando a entrada da fábrica. |
| Criador de Tarefas | Usa `speckit-tasks`; entrega tarefas por fase e história, com IDs, caminhos, dependências e cobertura dos requisitos. | Não implementa nem altera requisitos ou decisões do plano. |
| Desenvolvedor | Usa `speckit-implement`; entrega código, testes unitários e de integração, documentação de produto prevista e marcações de tarefas verificadas. | Executa somente a fase ou os apontamentos recebidos; não altera spec, plano ou testes do QA. |
| Revisor de Código | Entrega `review-report.md`, com arquivo, linha, severidade, impacto, correção sugerida e parecer; revisa também os testes do QA. | Revisa o intervalo ou os arquivos recebidos; não corrige código nem altera artefatos do Spec Kit. |
| QA | Cria testes de aceite nos locais do plano e entrega `qa-report.md` com rastreabilidade, execução real, defeitos reproduzíveis e parecer. | Não corrige produção, não altera requisitos nem artefatos do Spec Kit e não aprova sem executar testes. |

Os especialistas podem consultar o Git. As permissões de escrita em arquivos são
as do papel recebido e não incluem operações de escrita no Git, `gh` ou
`state.json`. Os formatos detalhados de handoff e retorno permanecem em
`src/orquestrador.md` e nos arquivos de cada papel.

## Fluxo de trabalho e critérios de avanço

O orquestrador aplica os critérios abaixo em sequência, além dos princípios anteriores.

| Etapa | Evidência necessária para avançar |
| --- | --- |
| E0 — Descoberta | Ferramentas, skills, roteador/configuração e pré-requisitos Git conferidos; constituição preenchida e ratificada; feature e branch identificadas; estado existente lido. Preparar a constituição é uma atividade anterior à execução da feature. |
| E1 — Especificação e Checkpoint 1 | `spec.md` e `checklists/requirements.md` completos, sem ambiguidades pendentes; respostas em `## Clarifications`; branch da feature conferida. O orquestrador salva a rodada, registra `AGUARDANDO_REVISAO_HUMANA`, apresenta requisitos, critérios e premissas e encerra o turno. E2 exige aprovação explícita registrada. |
| E2 — Plano técnico | `plan.md`, `research.md` e `quickstart.md` presentes; `data-model.md` e `contracts/` presentes quando aplicáveis; sem esclarecimentos pendentes ou erros; `Constitution Check` aprovado ou desvios justificados em `Complexity Tracking`; comandos de verificação registrados. |
| E3 — Tarefas | `tasks.md` no formato Spec Kit, organizado por fases e histórias, com caminhos, dependências e IDs preservados. |
| E3.5 — Consistência | `speckit-analyze` executado somente para leitura; nenhum achado `CRITICAL`; todo `FR-xxx` com tarefa correspondente. Inconsistências voltam ao responsável pelo artefato. |
| E4 — Implementação | Um acionamento do Desenvolvedor por fase. Em cada fase, tarefas verificadas e marcadas, comandos executados pelo orquestrador com saída `0`, IDs registrados e commit da fase. Para E5, nenhuma tarefa pode permanecer pendente. |
| E5 — Revisão | `review-report.md` presente, sem achados bloqueantes. Primeira revisão cobre a diferença desde a base; revisões seguintes cobrem as mudanças desde a última revisão aprovada. O orquestrador registra `last_reviewed_commit`. |
| E6 — Aceite | `qa-report.md` presente, com execução real da suíte e dos testes de aceite, sem defeito Crítico ou Alto nem teste falhando; testes criados ou alterados pelo QA revisados pelo Revisor. |
| E7 — PR e CI | Branch sincronizada com a base, verificações locais aprovadas, push e PR para a base registrada, descrição completa e CI verde. Sem CI, a ausência é registrada no estado e no PR, com validação local de todos os comandos previstos; criar CI fica como pendência, sem implementação automática. |
| E8 — Checkpoint 2 e entrega | PR apresentado ao humano, estado `AGUARDANDO_MERGE` e checkpoint de merge pendente. Só após merge pelo humano e confirmação via `gh pr view` o estado passa a `ENTREGUE`. |

Os marcadores `[P]` e `[USn]` identificam paralelismo possível entre tarefas e sua
história; `[X]` indica tarefa concluída e verificada. Eles são parte do formato
Spec Kit, não espaços pendentes de preenchimento. O marcador de paralelismo não
autoriza vários especialistas simultâneos no mesmo fluxo.

Uma mudança de spec invalida sua aprovação anterior. Se já houver plano, tarefas,
código ou PR, o orquestrador registra o possível descompasso e informa que a nova
aprovação retomará E2, com regeneração pelas skills na mesma branch e atualização
do PR existente. `checklists/requirements.md` incompleto retorna ao Analista;
outros checklists incompletos seguem a regra do orquestrador, com registro dos
itens como risco no PR.

## Governance

Esta constituição, versão `1.0.0`, foi aprovada e ratificada pelo humano em
`2026-11-21`, por mensagem explícita no chat: "Aprovo a proposta 1.0.0 da
constituição." Esta é a primeira adoção das regras do projeto como constituição.

Esta constituição governa as etapas da fábrica. `AGENTS.md`
define a entrada; `src/orquestrador.md` detalha o fluxo e os arquivos
`src/subagent-*.md` detalham os papéis. A constituição consolida essas regras e
não autoriza desvios silenciosos nem execução além do pedido humano.

Emendas são preparadas por `speckit-constitution`, com motivação, regras afetadas,
impacto nos artefatos e eventual migração descritos para revisão. O humano aprova
o novo texto antes da ratificação. Divergência entre documentos é registrada para
correção explícita; não é resolvida ignorando um checkpoint ou alterando escopo.
Templates e comandos dependentes não são modificados pela preparação da emenda.

O versionamento segue `MAJOR.MINOR.PATCH`: MAJOR para remoção ou redefinição
incompatível de princípios ou governança; MINOR para novos princípios, seções ou
ampliação material das regras; PATCH para esclarecimentos e correções sem mudança
de obrigação. A data original de ratificação é preservada nas emendas e
`Last Amended` registra a data da alteração em formato ISO.

O Arquiteto executa o `Constitution Check`; desvios devem ser justificados em
`Complexity Tracking`, com necessidade e alternativas. O Revisor verifica a
conformidade, o QA verifica o atendimento à spec e o orquestrador confere os
critérios antes de avançar e apresentar o PR. Justificativa técnica não aprova
mudança de requisito, não substitui aprovação humana e não altera permissões dos
papéis ou operações proibidas.

**Version**: 1.0.0 | **Ratified**: 2026-11-21 | **Last Amended**: 2026-11-21
