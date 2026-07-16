# Assinaturas E Cobrança

## Quando Ler Este Arquivo

Leia antes de alterar assinatura, plano, cobrança, cupons, webhooks de pagamento,
reconciliação, acesso da empresa por status comercial, limites de plano,
plano Starter gratuito ou qualquer fluxo ligado ao Mercado Pago.

## Visão Geral

`Subscription` modela o estado comercial da empresa no SaaS. O acesso ao sistema
depende da assinatura ativa, e mudanças nesse domínio podem afetar login,
onboarding, limites de plano, faturamento, auditoria e jobs de reconciliação.

`Plan` possui a flag `free`: existe um plano Starter gratuito (sem cobrança)
além dos planos pagos. Empresas no Starter fazem upgrade para plano pago pela
própria tela de configurações (`start_paid_subscription`), sem passar pelo
fluxo de cadastro.

## Áreas Relacionadas

- `register`: criação de empresa e assinatura inicial (inclusive no Starter).
- `app/gestor`: consulta de assinatura, upgrade a partir do Starter,
  cancelamento agendado e acesso operacional.
- `admin`: gestão de planos, assinaturas, empresas e reconciliação.
- `webhook`: callbacks do Mercado Pago.
- `suporte`: nível de suporte depende do plano; o Starter é restrito à base de
  conhecimento.
- Jobs e services: ciclos de cobrança, expiração, cancelamento e reconciliação
  (todos escopados a planos pagos via scope `paid_plan`).

## Pontos De Entrada Importantes

- `app/models/subscription.rb`
- `app/models/plan.rb`
- `app/models/company.rb` (`starter_plan?`, limites e `pdf_customization_available?`)
- `app/models/coupon.rb`
- `app/models/coupon_redemption.rb`
- `app/models/subscription_reconciliation_event.rb`
- `app/services/mercado_pago/subscriptions.rb`
- `app/services/mercado_pago/webhook_processor.rb`
- `app/services/coupons/redeem.rb`
- `app/services/coupons/signup_benefit_resolver.rb`
- `app/controllers/app/configurations_controller.rb` (`start_paid_subscription`,
  `cancel_subscription`, `resume_subscription`)
- `app/controllers/admin/subscriptions_controller.rb`
- `app/controllers/web_hook/mercado_pago_controller.rb`

## Regras De Negócio

### Planos e limites

- `Plan#free?` marca o plano gratuito (Starter); `Plan.paid` retorna somente
  planos com `free: false`. Plano pago exige `transaction_amount` positivo
  (validação `paid_plan_must_have_positive_amount`).
- Limites por plano: `max_technicians`, `max_orders`, `max_budgets` e
  `support_level`. Valor `nil` significa ilimitado.
- `Company#can_add_technician?` compara técnicos ativos com `max_technicians`.
  `can_create_order?` e `can_create_budget?` contam registros criados no mês
  corrente (a partir de `beginning_of_month`).
- `Company#starter_plan?` verifica `free?` no plano atual (`current_plan` ou
  `plan`). No Starter: não é possível adicionar técnicos (o gestor atua como
  técnico), tickets de suporte são bloqueados (validação em `SupportTicket`) e
  as seções de suporte redirecionam para a base de conhecimento.
- Personalização de PDF (`pdf_customization_available?`) só existe nos planos
  listados em `Company::PDF_CUSTOMIZATION_PLAN_NAMES` (Profissional e
  Enterprise) — a checagem é por nome do plano.

### Assinaturas

- Somente assinatura `active` concede acesso comercial via `allows_access?`.
- `Subscription` pertence a `Company`; qualquer consulta em área operacional
  deve preservar o escopo da empresa.
- `Plan` se relaciona com `Subscription` por `external_id` e
  `preapproval_plan_id`, não por `plans.id`.
- Assinatura de plano gratuito tem `end_date` sempre nulo
  (`clear_end_date_for_free_plan`, `before_validation`): não há ciclo de
  cobrança nem expiração.
- Os scopes de ciclo de vida de cobrança (`overdue_for_notification`,
  `overdue_for_expiration`, `ready_to_cycle`) usam o scope `paid_plan` e nunca
  alcançam o Starter.
- Cancelamento agendado só vale para assinatura ativa e usa
  `cancel_at_period_end`, `cancel_requested_at` e `cancel_effective_on`.
  `schedule_cancellation!` levanta erro para plano gratuito ("O plano Starter
  não possui cancelamento de assinatura"); a UI de configurações também não
  exibe o bloco de cancelamento no Starter.
- Reativar renovação só é válido quando existe cancelamento agendado.
- Upgrade de plano (`upgrade_to_plan!`) usa `PLAN_UPGRADE_RANKS`
  (Basico → Profissional → Enterprise) e não permite downgrade nem troca para
  o mesmo nível.
- Alterações de status ou dados comerciais devem preservar auditoria.

### Upgrade a partir do Starter (`start_paid_subscription`)

- Disponível apenas quando a assinatura ativa atual é de plano gratuito
  (`current_active_subscription&.free_plan?`); planos pagos usam o fluxo de
  upgrade/cancelamento existente.
- Exige plano pago ativo (`Plan.paid.where(status: :active)`) e forma de
  pagamento válida (`Company::PAYMENT_METHODS`: `pix`, `credit_card`,
  `boleto`). Cartão exige `card_token`.
- Cria assinatura `pending` para o plano escolhido, cancela outras pendências
  de planos diferentes e atualiza `payment_method` da empresa. A assinatura
  Starter ativa permanece até a confirmação do pagamento.
- Pagamento: boleto e PIX disparam jobs (`CreateUser::BoletoPaymentJob`,
  `CreateUser::PixPaymentJob`); cartão chama
  `Cmd::MercadoPago::CreateCreditCardPayment` de forma síncrona. Falha no
  início do pagamento cancela a assinatura pendente.
- Gera auditoria `subscription.paid_signup.started`.
- `activate_as_current!` ativa a nova assinatura, cancela as demais ativas da
  empresa e atualiza `company.plan`.

### Cupons

- `Coupon#benefit_type`: `discount` (percentual ou valor fixo) ou `trial`
  (período gratuito com `trial_frequency` + `trial_frequency_type`).
- Cupom de desconto exige `discount_type` e `discount_value`; cupom trial não
  pode ter desconto financeiro e exige duração do teste.
- Disponibilidade: `active`, janela `valid_from`/`valid_until` e
  `max_redemptions` (contador `redemptions_count`).
- Resgate (`CouponRedemption`): único por assinatura (`subscription_id`
  unique) e no máximo um cupom por empresa a cada 12 meses
  (`used_by_company_within_last_year?`).
- `Coupons::SignupBenefitResolver` valida o cupom no signup: desconto que
  zera o valor deve ser cadastrado como trial; cupom de desconto não é
  suportado com cartão de crédito nesse fluxo; rejeições geram auditoria
  `coupon.rejected`.
- `Coupons::Redeem` registra o resgate com valores original, desconto e final.

## Estados E Transições

- Status conhecidos: `pending`, `active`, `cancelled`, `expired`.
- `activate_for!` define período, limpa cancelamento e expiração.
- `activate_as_current!` ativa e cancela as outras assinaturas ativas da
  empresa, sincronizando `company.plan`.
- `cancel!` cancela imediatamente.
- `expire!` marca expiração.
- `schedule_cancellation!` agenda cancelamento no fim do período (bloqueado
  para plano gratuito).
- `resume_cancellation!` remove o cancelamento agendado.
- `finalize_scheduled_cancellation!` efetiva cancelamento quando a data vence.
- Mudança de `status` dispara `sync_company_access`: ativa ou desativa a
  empresa e seus usuários.
- Starter: assinatura `active` sem `end_date`, sem renovação e sem
  cancelamento; a saída do Starter acontece via `start_paid_subscription`.

## Riscos Comuns

- Quebrar acesso de empresas ativas ao mudar `allows_access?`.
- Ignorar `company_id` em consultas administrativas reaproveitadas na área `app`.
- Confundir id interno de plano com ids externos do Mercado Pago.
- Alterar status sem manter campos auxiliares coerentes.
- Tratar `end_date` como sempre presente: no Starter ele é nulo. Jobs e
  queries de cobrança devem usar o scope `paid_plan` para não processar o
  plano gratuito.
- Permitir cancelamento, expiração ou cobrança de assinatura de plano
  gratuito.
- Esquecer que limites `nil` significam ilimitado ao validar
  `max_technicians`/`max_orders`/`max_budgets`.
- Checar personalização de PDF por flag em vez de
  `pdf_customization_available?` (a regra é por nome de plano).
- Duplicar pagamento ou processar webhook repetido sem idempotência.
- Remover registros com cupons ou reconciliações sem considerar dependências.

## Testes Recomendados

- Testes de model para `Subscription`, `Plan`, `Coupon` e `CouponRedemption`.
- Testes de `end_date` nulo e bloqueio de cancelamento em assinatura de plano
  gratuito.
- Testes de services em `MercadoPago::Subscriptions`, webhook processor e cupons.
- Testes de `App::ConfigurationsController#start_paid_subscription`
  (autorização, plano pago ativo, formas de pagamento, falha de pagamento).
- Testes de limites de plano em `Company` (`can_add_technician?`,
  `can_create_order?`, `can_create_budget?`) e de restrições do Starter
  (suporte e técnicos).
- Testes de controllers de assinatura em `admin`, `register` e `webhook`.
- Testes de acesso quando status muda entre `pending`, `active`, `cancelled` e
  `expired`.
