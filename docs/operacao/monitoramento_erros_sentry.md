# Monitoramento de Erros (Sentry)

## Objetivo

Padronizar a configuração de monitoramento de erros para ambiente produtivo e o uso da tela **Admin > Métricas**.

## Variáveis de ambiente

Defina no ambiente de deploy:

- `SENTRY_DSN` (obrigatória)
- `SENTRY_ENVIRONMENT` (opcional, default `Rails.env`)
- `SENTRY_TRACES_SAMPLE_RATE` (opcional, default `0.1`)
- `SENTRY_RELEASE` (opcional, recomendada para rastrear deploy)
- `SENTRY_PROJECT_URL` (opcional, usada como atalho visual em Admin > Métricas)

## Comportamento no sistema

- Inicialização do Sentry em `config/initializers/sentry.rb`.
- Ambientes habilitados por padrão: `production` e `staging`.
- Contexto enviado para o Sentry:
  - usuário (`id`, `email`)
  - empresa (`id`, `name`)
  - request (`request_id`, `ip_address`, `user_agent`)
  - tags (`subdomain`, `controller`, `action`)
- Exclusões de ruído:
  - `CanCan::AccessDenied`
  - `ActionController::RoutingError`

## Admin > Métricas

A tela exibe:

- status do Sentry (configurado e ativo no ambiente);
- falhas por janela (`24h`, `7d`, `30d`) para:
  - `job.failed`
  - `webhook.failed`
  - `report.export.failed`
- saúde do Sidekiq (processos, fila default, retries, dead set);
- botão **Testar Sentry** para envio de evento controlado;
- timestamp de última atualização.

## Teste operacional

1. Acesse `admin` > `Métricas`.
2. Clique em **Testar Sentry**.
3. Valide no Sentry o evento de teste.
4. Valide em `AuditEvent` a ação `system.monitoring.test_triggered`.

## Alertas recomendados

Configurar no Sentry:

- novo erro com frequência acima de 5 eventos em 10 minutos;
- aumento de falha em jobs críticos em 15 minutos;
- crescimento de falhas de exportação;
- crescimento de falhas de webhook.

## Observações

- Métricas de falha dependem de `AuditEvent`.
- Falhas de `ActiveJob` são registradas automaticamente como `job.failed` via `ApplicationJob`.
