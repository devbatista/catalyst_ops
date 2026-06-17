# Integrações E Webhooks

## Quando Ler Este Arquivo

Leia antes de alterar webhooks, Mercado Pago, callbacks externos, eventos
persistidos, idempotência, secrets, reconciliação ou clientes HTTP externos.

## Visão Geral

Integrações externas conectam o CatalystOps a provedores de pagamento e outros
serviços. O principal provedor atual é Mercado Pago, usado em assinaturas,
planos, pagamentos e webhooks.

## Areas Relacionadas

- `webhook`: entrada HTTP para callbacks externos.
- `admin`: reconciliação e diagnóstico.
- Jobs/services: processamento assíncrono e chamadas externas.
- `register` e assinaturas: criação e atualização de planos/pagamentos.

## Pontos De Entrada Importantes

- `app/controllers/web_hook_controller.rb`
- `app/controllers/web_hook/mercado_pago_controller.rb`
- `app/services/mercado_pago/client.rb`
- `app/services/mercado_pago/subscriptions.rb`
- `app/services/mercado_pago/webhook_processor.rb`
- `app/models/webhook_event.rb`
- `app/models/subscription_reconciliation_event.rb`

## Regras De Negócio

- Webhooks devem ser tratados com idempotência.
- Eventos externos devem preservar rastreabilidade suficiente para auditoria e
  reconciliação.
- Secrets e tokens devem vir de configuração segura, não hardcoded.
- Falhas externas devem ser registradas sem quebrar consistência local.
- Processamento de pagamento deve respeitar assinatura, empresa e plano
  corretos.

## Estados E Transições

- `WebhookEvent` usa status de processamento para rastrear eventos recebidos.
- Reconciliações podem registrar divergência, erro, resolução e origem do job.
- Eventos de pagamento podem alterar assinatura e acesso da empresa.

## Riscos Comuns

- Processar o mesmo webhook mais de uma vez.
- Confiar em payload externo sem validar assinatura/secret quando aplicável.
- Atualizar assinatura errada por usar identificador incompleto.
- Perder payload bruto necessário para diagnóstico.
- Fazer chamada externa em teste sem mock/stub.

## Testes Recomendados

- Testes de webhook com payload válido, inválido e duplicado.
- Testes de processor com eventos repetidos.
- Testes de reconciliação com divergências.
- Testes com stubs para cliente Mercado Pago.
