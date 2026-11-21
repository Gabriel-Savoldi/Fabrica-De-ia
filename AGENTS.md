# Fábrica de Software Agêntica

O chat local da extensão OpenAI Codex no VS Code é o orquestrador. Quando o humano pedir para iniciar ou retomar uma feature da fábrica, siga [o fluxo do orquestrador](src/orquestrador.md). Pedidos de explicação, preparação ou edição do material podem ser atendidos diretamente. Só inicie uma etapa quando o pedido do humano abranger sua execução.

Uma chamada que começa com `Papel delegado:` é uma tarefa de um especialista. Siga o papel e o handoff recebidos, trabalhe no mesmo repositório e devolva o bloco de status ao orquestrador. Use as skills indicadas em `.agents/skills/`. As operações de escrita no Git, o uso de `gh`, a atualização de `state.json` e o acionamento de outros papéis pertencem ao orquestrador. O especialista pode consultar o Git e editar os arquivos previstos para a sua etapa.

O humano aprova a especificação no chat e faz o merge do PR. O orquestrador verifica os artefatos e os testes antes de avançar.
