# LGPD / Termos / Auditoria (Item 9)

Este documento consolida a revisão do bloco **9) LGPD / termos / auditoria** do checklist de pendências.

## 1. Política de retenção de dados de auditoria

- Base: tabela `audit_events`.
- Retenção padrão: **180 dias**.
- Limpeza automática: job `Audit::CleanupEventsJob` (Sidekiq Cron, diário às 02:00 `America/Sao_Paulo`).
- Serviço usado: `Audit::CleanupOldEvents`.

Variáveis de ambiente:

- `AUDIT_LOG_RETENTION_DAYS` (padrão: `180`)
- `AUDIT_LOG_CLEANUP_BATCH_SIZE` (padrão: `1000`)
- `AUDIT_LOG_CLEANUP_DRY_RUN` (padrão: `false`)

## 2. Trilha mínima de auditoria para eventos críticos

Eventos críticos já cobertos no catálogo:

- Autenticação: `auth.login.succeeded`, `auth.login.failed`, `auth.logout.succeeded`
- Webhook: `webhook.received`, `webhook.duplicate`, `webhook.processed`, `webhook.failed`
- Assinaturas: `subscription.*` (criação, mudança de status, pagamentos, reconciliação)
- Ordens de serviço: `order_service.*` (criação, edição, status, anexos, comprovantes)
- Relatórios: `report.export.*` e download
- Jobs/sistema: `job.*`
- Termos: `terms.accepted`

Campos de evidência no `audit_events`:

- `occurred_at`
- `action`, `source`
- `actor_type`, `actor_id`
- `company_id`
- `resource_type`, `resource_id`
- `request_id`, `ip_address`, `user_agent`
- `metadata` em JSON estruturado

## 3. Fluxo de aceite de termos e evidências

Fluxos com registro de evidência:

- Signup (`Register::SignupsController`): após criar empresa/usuário, o sistema registra aceite dos termos e gera `terms.accepted`.
- App (`App::TermsOfUseController`): quando usuário aceita termos pendentes, o sistema atualiza dados de aceite e gera `terms.accepted`.

Evidências salvas na empresa:

- `terms_version_accepted`
- `terms_accepted_at`
- `terms_accepted_ip`
- `terms_accepted_user_agent`
- `terms_accepted_by_user_id`

Evidências no log (`metadata` do evento `terms.accepted`):

- versão aceita
- data/hora de aceite
- IP do aceite
- usuário responsável pelo aceite
- fluxo (`signup`, quando aplicável)
