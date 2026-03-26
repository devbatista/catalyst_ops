# Queries operacionais

Esta pasta concentra queries operacionais em arquivos `.rb` para diagnostico e operacao.

- As queries sao somente leitura.
- Podem ser executadas por comando em `Cmd::Queries::RunOperationalQuery`.
- Quando houver janela de dias, use parametro `window_days` (padrao: 30).

## Queries disponiveis

- `:pending_pix_boleto_without_processed_webhook`
- `:reconciliation_window_summary`
- `:payment_events_status_breakdown`
- `:possible_duplicate_payment_events`

## Exemplo de uso no console

```ruby
Cmd::Queries::RunOperationalQuery.available_queries

result = Cmd::Queries::RunOperationalQuery.new(
  query_name: :pending_pix_boleto_without_processed_webhook,
  params: { window_days: 30 }
).call

result.success?
result.columns
result.rows.first
```
