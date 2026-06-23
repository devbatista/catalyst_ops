# Orçamentos

## Quando Ler Este Arquivo

Leia antes de alterar criação, envio, aprovação, rejeição ou conversão de
orçamentos em ordens de serviço.

## Visão Geral

`Budget` representa uma proposta comercial/operacional vinculada a uma empresa
e cliente. Ele pode originar uma OS quando aprovado, e compartilha itens de
serviço com cálculos financeiros.

## Áreas Relacionadas

- `app/gestor`: cria, edita, envia e acompanha orçamentos.
- `cliente`: fluxo externo de aprovação ou rejeição.
- Relatórios: indicadores de orçamentos por status.

## Pontos De Entrada Importantes

- `app/models/budget.rb`
- `app/models/service_item.rb`
- `app/models/client.rb`
- `app/models/order_service.rb`
- `app/controllers/app/budgets_controller.rb`
- `app/controllers/cliente/budget_approvals_controller.rb`

## Regras De Negócio

- Orçamento pertence a `Company` e `Client`.
- Código deve ser único por empresa.
- `order_service_id` é único quando o orçamento vira OS.
- Total deve refletir os itens de serviço e seus valores.
- Fluxos de aprovação externa devem preservar segurança e escopo.

## Estados E Transições

- Consulte `Budget.statuses` antes de alterar regras de status.
- O envio para aprovação, aprovação, rejeição e conversão em OS devem manter
  timestamps e vínculos coerentes.

## Riscos Comuns

- Permitir que um orçamento gere mais de uma OS.
- Recalcular total ignorando quantidade.
- Expor orçamentos entre empresas.
- Quebrar links externos de aprovação.

## Testes Recomendados

- Testes de model para status, total e unicidade por empresa.
- Testes de controller/request para fluxo do gestor.
- Testes do fluxo externo de aprovação/rejeição.
- Testes de conversão de orçamento aprovado em OS.
