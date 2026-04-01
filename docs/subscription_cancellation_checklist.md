# Checklist Técnico - Cancelamento de Assinatura no Fim do Período

## Entregue neste incremento
- [x] Campos de cancelamento agendado em `subscriptions`:
  - `cancel_at_period_end`
  - `cancel_requested_at`
  - `cancel_effective_on`
  - `cancel_reason`
- [x] Regras de domínio na model `Subscription`:
  - agendar cancelamento
  - reativar renovação
  - identificar cancelamento devido
  - finalizar cancelamento quando chegar a data efetiva
  - proteger transições inválidas fora do controller (`RecordInvalid` para chamadas indevidas)
- [x] Fluxo da tela `Configurações > Assinatura`:
  - botão para cancelar no fim do período
  - aviso de assinatura agendada para cancelamento
  - botão para reativar renovação
- [x] Rotas e ações de controller:
  - `cancel_subscription`
  - `resume_subscription`
- [x] Job de finalização automática:
  - `Subscriptions::FinalizeScheduledCancellationsJob`
  - command `Cmd::Subscriptions::FinalizeScheduledCancellation`
- [x] Ajuste na ciclagem:
  - assinatura com `cancel_at_period_end = true` não entra em `ready_to_cycle`

## Pendências para fechar o fluxo (hardening)
- [x] Cancelamento remoto no gateway para assinaturas de cartão de crédito (preapproval no Mercado Pago).
- [ ] Adicionar proteção para impedir agendamento em assinaturas não ativas no nível de policy/ability (além do controller).
- [ ] Cobrir fluxo completo com specs (model, controller, job e command).
- [ ] Exibir histórico de cancelamento no admin (quem solicitou, quando solicitou, data efetiva e motivo).
- [ ] Definir copy final de UX para confirmação de cancelamento e reativação.
