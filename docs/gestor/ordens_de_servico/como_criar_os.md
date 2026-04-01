# Como criar uma Ordem de Serviço (via orçamento aprovado)

## Quando usar
Use este fluxo quando você precisar gerar uma OS no sistema.  
No fluxo atual, a OS é criada automaticamente após aprovação de um orçamento.

## Passo a passo
1. Acesse **Orçamentos** no menu lateral, ou abra o cliente e clique em **Novo Orçamento**.
2. Preencha título, descrição, validade e itens de serviço.
3. Clique em **Salvar**.
4. Envie para aprovação do cliente pelo botão **Enviar ao cliente**.
5. Quando o orçamento for aprovado (cliente ou gestor), a OS será criada automaticamente.

## O que acontece depois
A OS é criada com status **Pendente** e aparece na listagem de Ordens de Serviço para seguir fluxo operacional (atribuição, agendamento, execução e finalização).

## Erros comuns
- Tentar criar OS diretamente por URL antiga (`/order_services/new`).
- Enviar orçamento sem itens de serviço.
- Aprovar orçamento sem revisar validade e descrição.

## Dicas
- Use orçamento como fonte única de escopo e valores.
- Defina itens de serviço com descrição clara para evitar retrabalho na OS gerada.
- Em caso de rejeição do orçamento, revise e salve novamente antes de reenviar.
