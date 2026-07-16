# Onboarding

## Quando Ler Este Arquivo

Leia antes de alterar o checklist de primeiros passos, o modal de boas-vindas
do dashboard, o tracking automático de etapas ou as métricas de ativação e
retenção no admin.

## Visão Geral

`UserOnboardingProgress` registra, por usuário, o progresso nas etapas de
primeiros passos (técnico, cliente, orçamento, primeira OS, mudança de status
e relatórios). O dashboard exibe modal de boas-vindas e checklist, os
controllers marcam etapas automaticamente e o admin acompanha ativação e
retenção D7.

## Áreas Relacionadas

- `app/gestor`: modal de boas-vindas, checklist e tour no dashboard.
- Controllers operacionais: marcam etapas via `OnboardingTracking`.
- `admin`: métricas de ativação, conclusão, dismiss e retenção D7.

## Pontos De Entrada Importantes

- `app/models/user_onboarding_progress.rb`
- `app/controllers/app/onboarding_progress_controller.rb`
- `app/controllers/concerns/onboarding_tracking.rb`
- `app/controllers/app/dashboard_controller.rb`
- `app/views/app/dashboard/_onboarding_welcome_modal.html.erb`
- `app/views/app/dashboard/_onboarding_checklist.html.erb`
- `app/views/app/dashboard/_onboarding_tour.html.erb`
- `app/controllers/admin/metrics_controller.rb`

## Regras De Negócio

- `STEP_KEYS` define as 6 etapas válidas: `created_technician`,
  `created_customer`, `created_budget`, `created_first_work_order`,
  `moved_work_order_status`, `viewed_reports`.
- Um registro de progresso por usuário (`user_id` único); o endpoint JSON usa
  `find_or_create_by!`.
- `completed_steps` é normalizado antes da validação: chaves fora de
  `STEP_KEYS` são descartadas e valores viram booleanos estritos.
- `progress_percentage` é a razão entre etapas concluídas e o total de
  `STEP_KEYS`, arredondada.
- `complete_step!` marca a etapa, atualiza `last_seen_step`, preenche
  `finished_at` quando todas as etapas estão completas e retorna se a etapa
  era inédita. Chave inválida levanta `ArgumentError`.
- O endpoint `App::OnboardingProgressController` (show/update JSON) aceita
  apenas as operações `complete_step`, `dismiss`, `resume`, `finish` e
  `set_last_seen`; `complete_step` e `set_last_seen` exigem `step_key`.
- `OnboardingTracking#mark_onboarding_step` é best-effort: falhas são apenas
  logadas (warn) e não quebram a ação principal do controller.
- Etapas são marcadas nos controllers: técnico criado, cliente criado,
  orçamento criado, aprovação de orçamento (primeira OS), mudança de status
  de OS e visualização de relatórios.
- O modal de boas-vindas só aparece para usuário sem progresso ou com
  progresso "zerado" (sem dismiss, sem finish, sem `last_seen_step` e sem
  etapas concluídas); o checklist é exibido para não técnicos.
- Métricas do admin usam coorte de usuários `admin`/`gestor` com empresa,
  criados no período selecionado (24h/7d/30d): taxa de conclusão, taxa de
  dismiss, primeira OS em até 24h, tempo médio até a primeira OS e retenção
  D7 (algum `AuditEvent` do usuário entre o 7º e o 8º dia após o cadastro).

## Estados E Transições

- O progresso não usa enum: o estado deriva de `completed_steps`,
  `dismissed_at`, `finished_at` e `last_seen_step`.
- `dismiss!` preenche `dismissed_at`; `resume!` limpa; `finish!` preenche
  `finished_at`; `complete_step!` pode finalizar automaticamente quando
  `finished_all_steps?` é verdadeiro.

## Riscos Comuns

- Adicionar etapa nova sem atualizar `STEP_KEYS`, o checklist do dashboard e
  as métricas de conclusão.
- Aceitar `step_key` fora de `STEP_KEYS` (o model levanta `ArgumentError`).
- Fazer o tracking de onboarding quebrar a ação principal (deve permanecer
  best-effort, com rescue e log).
- Reexibir o modal de boas-vindas para usuário que já dispensou, finalizou ou
  progrediu no checklist.
- Alterar a coorte ou a janela D7 das métricas do admin sem revisar as taxas
  exibidas.

## Testes Recomendados

- Testes de model para `complete_step!`, normalização de `completed_steps`,
  percentual e finalização automática.
- Testes de request do endpoint JSON (show/update) cobrindo operações válidas,
  inválidas e `step_key` ausente.
- Testes dos controllers que marcam etapas via `mark_onboarding_step`.
- Testes de elegibilidade do modal de boas-vindas no dashboard.
- Testes das métricas de onboarding no admin (coorte, conclusão, D7).
