# Admin Backoffice

## Quando Ler Este Arquivo

Leia antes de alterar qualquer tela ou controller do subdomínio `admin`:
dashboard, empresas, usuários, assinaturas, reconciliação, planos, cupons,
OS, tickets, base de conhecimento, logs, métricas, configurações ou coverage.

## Visão Geral

O backoffice administrativo roda no subdomínio `admin` e é a visão interna da
plataforma. Ele é cross-tenant: consulta dados de todas as empresas, sem escopo
por `company_id`. O acesso exige usuário com role `admin` — qualquer outro
usuário é redirecionado para o subdomínio de login com alerta de acesso negado.

Seções e finalidades:

- Dashboard: indicadores globais (empresas ativas, assinaturas ativas, MRR
  estimado, tickets abertos, novos cadastros no mês, OS finalizadas/atrasadas,
  top empresas por OS, tickets recentes e assinaturas em atenção).
- Empresas: listagem com busca e paginação; detalhe mostra tickets abertos.
- Usuários: listagem com busca, filtro por role e detalhe.
- Assinaturas: listagem e detalhe, somente leitura no controller.
- Reconciliação de assinaturas: listagem e detalhe de
  `SubscriptionReconciliationEvent`, somente leitura (`only: [:index, :show]`),
  com filtros por busca, `result_status`, `source_job`, `divergent` e
  `resolved`.
- Planos: CRUD parcial (index, show, new, create, edit, update) de `Plan`.
- Cupons: CRUD completo de `Coupon`, com filtros por busca, status e
  `benefit_type`.
- Ordens de serviço: listagem, detalhe com itens e geração de PDF via
  `Cmd::Pdf::Create`.
- Tickets: listagem com filtros (status, categoria, busca), detalhe com
  mensagens e ação `resolve`.
- Mensagens de suporte: criação de resposta em ticket (`only: [:create]`),
  com anexos e notificação.
- Base de conhecimento: CRUD de `KnowledgeBaseArticle` com filtros por
  categoria, audiência e busca.
- Logs: listagem e detalhe de `AuditEvent` com filtros e exportação CSV.
- Métricas: status do Sentry, indicadores de erro por auditoria, filas do
  Sidekiq e funil de onboarding/ativação.
- Configurações: painel somente leitura de status de serviços e integrações,
  mais edição do próprio perfil do admin.
- Coverage: relatório de cobertura de testes, disponível apenas em
  development.

## Áreas Relacionadas

- `docs/dev/ai/auditoria_e_operacao.md`: logs de auditoria e queries
  operacionais consumidos pela tela de logs.
- `docs/dev/ai/assinaturas.md`: assinaturas, planos e reconciliação exibidos
  no admin.
- `docs/dev/ai/suporte_e_base_conhecimento.md`: tickets, mensagens e artigos
  gerenciados pelo admin.
- `docs/dev/ai/financeiro_e_relatorios.md`: métricas globais da plataforma.
- `docs/dev/ai/usuarios_e_permissoes.md`: role `admin` e regras de acesso.

## Pontos De Entrada Importantes

- `config/routes/admin.rb`
- `app/controllers/admin_controller.rb`
- `app/controllers/admin/dashboard_controller.rb`
- `app/controllers/admin/companies_controller.rb`
- `app/controllers/admin/users_controller.rb`
- `app/controllers/admin/subscriptions_controller.rb`
- `app/controllers/admin/subscription_reconciliation_events_controller.rb`
- `app/controllers/admin/plans_controller.rb`
- `app/controllers/admin/coupons_controller.rb`
- `app/controllers/admin/order_services_controller.rb`
- `app/controllers/admin/tickets_controller.rb`
- `app/controllers/admin/support_messages_controller.rb`
- `app/controllers/admin/knowledge_base_articles_controller.rb`
- `app/controllers/admin/logs_controller.rb`
- `app/controllers/admin/metrics_controller.rb`
- `app/controllers/admin/configurations_controller.rb`
- `app/controllers/admin/coverage_controller.rb`
- `app/models/subscription_reconciliation_event.rb`

## Regras De Negócio

- Todo controller do admin herda de `AdminController`, que aplica
  `require_admin` (`current_user&.admin?`) e `skip_authorization_check`;
  a proteção vem do role, não do CanCan.
- O admin é cross-tenant por design: as consultas não são escopadas por
  empresa. Não adicionar escopo de tenant nem reutilizar essas queries em
  áreas de gestor.
- Planos: `plan_params` inclui limites (`max_technicians`, `max_orders`,
  `max_budgets`), `support_level`, `transaction_amount` e flag `free`. Plano
  pago deve ter `transaction_amount` positivo (validação em `Plan`). O plano
  Starter é o plano com `free: true` (`Company#starter_plan?`) e assinaturas
  de plano free não podem ser agendadas para cancelamento.
- Cupons: `benefit_type` é `discount` ou `trial`; desconto usa `percentage`
  ou `fixed_amount`; trial exige `trial_frequency` e `trial_frequency_type`.
  O `new` já sugere `active`, `discount`, `percentage` e `first_cycle_only`.
  Exclusão é bloqueada quando há resgates vinculados
  (`ActiveRecord::DeleteRestrictionError`).
- Tickets: admin não cria nem edita tickets (`only: [:index, :show]` mais
  `resolve`). `resolve` usa `mark_as_resolved!` e dispara
  `SupportTicketNotifications.notify_status_changed`. Respostas entram por
  `Admin::SupportMessagesController#create` via `ticket.add_message!`, com
  anexos e `notify_message`; erro de validação re-renderiza
  `admin/tickets/show` com 422.
- Reconciliação de assinaturas é somente leitura no admin: os eventos são
  gerados por jobs (campo `source_job`) e a tela só lista e detalha.
- Logs: filtros por busca (nome/e-mail do ator, `actor_id`, `request_id`,
  `resource_id`), action, source, empresa e período (`occurred_at`).
  Exportação CSV usa `Cmd::Exports::GenerateCsv` com template `:admin_logs`
  e lotes de 1000. `per` só aceita 10, 20, 30 ou 50.
- Métricas: períodos fixos de 24h, 7d e 30d. Indicadores de erro contam
  `AuditEvent` das actions `job.failed`, `report.export.failed` e
  `webhook.failed`. Sidekiq lê `ProcessSet`, fila `default`, retries e dead
  set com fallback zerado em erro. Onboarding usa coorte de usuários
  `admin`/`gestor` com empresa criados no período, medindo conclusão e
  dismissal do onboarding, primeira OS em 24h, tempo médio até a primeira OS
  e retenção D7 via eventos de auditoria. `test_sentry` envia exceção de
  teste ao Sentry e audita `system.monitoring.test_triggered`.
- Configurações: painel derivado de ENV e checagens em runtime (banco, Redis,
  Sidekiq, Mercado Pago, webhook secret, SMTP). A única escrita é o perfil do
  próprio admin (`id` fixo `"profile"`, permitindo `name`, `phone` e senha);
  qualquer outro `id` retorna alerta de configuração não encontrada.
- Coverage: rota e mount de `/coverage_report` só existem em development; o
  controller lê `coverage/.last_run.json` e `coverage/.resultset.json`.

## Estados E Transições

- `SubscriptionReconciliationEvent` registra `local_status_before` e
  `local_status_after` da assinatura, com `result_status` em `success` ou
  `error`, além das flags `divergent` e `resolved` (scopes `recent`,
  `divergent`, `errors`).
- Ticket resolvido via `resolve` transita pelo `mark_as_resolved!` do
  `SupportTicket`; o status anterior é preservado para a notificação.
- Planos possuem `status` (`active`/`inactive`) e flag `free`; o Starter é o
  plano free e não passa pelo fluxo de cancelamento de assinatura.
- Cupons alternam `active`/inativo e diferem em comportamento por
  `benefit_type` (`discount` zera parte do valor; `trial` zera o ciclo).

## Riscos Comuns

- Rota órfã: `resources :contents` em `config/routes/admin.rb` não possui
  `Admin::ContentsController` correspondente — qualquer acesso a essas rotas
  falha em runtime. Remover a rota ou criar o controller antes de referenciar
  `admin_contents_*` em views.
- `resources :plans`, `:companies`, `:users` e `:subscriptions` geram rotas
  completas (incluindo `destroy`), mas os controllers implementam apenas
  parte das actions; linkar rotas sem action implementada quebra em runtime.
- Escopar consultas do admin por empresa por engano, ou reutilizar queries
  cross-tenant do admin em telas de gestor (vazamento entre tenants).
- Afrouxar `require_admin` ou reintroduzir authorization check sem regras,
  já que os controllers usam `skip_authorization_check`.
- Criar plano pago com `transaction_amount` zerado ou marcar plano errado
  como `free`, mudando quem é tratado como Starter.
- Excluir cupom com resgates: o controller trata
  `DeleteRestrictionError`, mas mudanças na associação podem quebrar isso.
- Transformar a tela de reconciliação em escrita — ela é somente leitura por
  design.
- Quebrar filtros ou o template CSV de logs (`:admin_logs`), usados em
  investigação operacional.
- Depender de Sidekiq/Redis nas métricas sem os fallbacks de erro existentes.

## Testes Recomendados

- Testes de acesso: usuário sem role admin redirecionado ao login em todos os
  controllers do subdomínio.
- Testes de filtros e paginação em empresas, usuários, tickets, cupons,
  reconciliação e logs.
- Testes de `resolve` de ticket e criação de mensagem com anexos, incluindo
  notificações e re-render com 422.
- Testes de CRUD de planos (validação de valor em plano pago) e de cupons
  (discount vs trial, bloqueio de exclusão com resgates).
- Testes de exportação CSV de logs e dos filtros por período.
- Testes de métricas com coorte de onboarding e fallbacks de Sidekiq.
- Teste de configurações restringindo escrita ao `id` `"profile"`.
