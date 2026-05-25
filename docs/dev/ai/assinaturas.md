# Assinaturas E Cobrança

## Quando Ler Este Arquivo

Leia antes de alterar assinatura, plano, cobrança, cupons, webhooks de pagamento,
reconciliação, acesso da empresa por status comercial ou qualquer fluxo ligado
ao Mercado Pago.

## Visão Geral

`Subscription` modela o estado comercial da empresa no SaaS. O acesso ao sistema
depende da assinatura ativa, e mudanças nesse domínio podem afetar login,
onboarding, limites de plano, faturamento, auditoria e jobs de reconciliação.

## Areas Relacionadas

- `register`: criação de empresa e assinatura inicial.
- `app/gestor`: consulta de assinatura e acesso operacional.
- `admin`: gestão de planos, assinaturas, empresas e reconciliação.
- `webhook`: callbacks do Mercado Pago.
- Jobs e services: ciclos de cobrança, expiração, cancelamento e reconciliação.

## Pontos De Entrada Importantes

- `app/models/subscription.rb`
- `app/models/plan.rb`
- `app/models/coupon.rb`
- `app/models/coupon_redemption.rb`
- `app/models/subscription_reconciliation_event.rb`
- `app/services/mercado_pago/subscriptions.rb`
- `app/services/mercado_pago/webhook_processor.rb`
- `app/services/coupons/redeem.rb`
- `app/services/coupons/signup_benefit_resolver.rb`
- `app/controllers/admin/subscriptions_controller.rb`
- `app/controllers/web_hook/mercado_pago_controller.rb`

## Regras De Negócio

- Somente assinatura `active` concede acesso comercial via `allows_access?`.
- `Subscription` pertence a `Company`; qualquer consulta em área operacional
  deve preservar o escopo da empresa.
- `Plan` se relaciona com `Subscription` por `external_id` e
  `preapproval_plan_id`, não por `plans.id`.
- Upgrade de plano não permite downgrade nem troca para o mesmo nível no fluxo
  atual.
- Cancelamento agendado só vale para assinatura ativa e usa
  `cancel_at_period_end`, `cancel_requested_at` e `cancel_effective_on`.
- Reativar renovação só é válido quando existe cancelamento agendado.
- Cupons aplicados ficam em `CouponRedemption` e há unicidade por assinatura.
- Alterações de status ou dados comerciais devem preservar auditoria.

## Estados E Transições

- Status conhecidos: `pending`, `active`, `cancelled`, `expired`.
- `activate_for!` define período, limpa cancelamento e expiração.
- `cancel!` cancela imediatamente.
- `expire!` marca expiração.
- `schedule_cancellation!` agenda cancelamento no fim do período.
- `resume_cancellation!` remove o cancelamento agendado.
- `finalize_scheduled_cancellation!` efetiva cancelamento quando a data vence.

## Riscos Comuns

- Quebrar acesso de empresas ativas ao mudar `allows_access?`.
- Ignorar `company_id` em consultas administrativas reaproveitadas na área `app`.
- Confundir id interno de plano com ids externos do Mercado Pago.
- Alterar status sem manter campos auxiliares coerentes.
- Duplicar pagamento ou processar webhook repetido sem idempotência.
- Remover registros com cupons ou reconciliações sem considerar dependências.

## Testes Recomendados

- Testes de model para `Subscription`, `Plan`, `Coupon` e `CouponRedemption`.
- Testes de services em `MercadoPago::Subscriptions`, webhook processor e cupons.
- Testes de controllers de assinatura em `admin`, `register` e `webhook`.
- Testes de acesso quando status muda entre `pending`, `active`, `cancelled` e
  `expired`.
