# Financeiro E Relatorios

## Quando Ler Este Arquivo

Leia antes de alterar área financeira, dashboards, relatórios, exportações CSV,
métricas, somatórios, filtros por período ou indicadores de OS e orçamentos.

## Visão Geral

O financeiro operacional deriva principalmente de OS e itens de serviço. Ele
não deve ser confundido automaticamente com cobrança SaaS da plataforma, que
pertence ao domínio de assinaturas.

## Areas Relacionadas

- `app/gestor`: dashboard, financeiro e relatórios.
- `admin`: métricas globais e acompanhamento da plataforma.
- Exportações: CSV e relatórios operacionais.

## Pontos De Entrada Importantes

- `app/controllers/app/financial_controller.rb`
- `app/controllers/app/reports_controller.rb`
- `app/controllers/app/dashboard_controller.rb`
- `app/services/reports/export_builder.rb`
- `app/services/exports/csv_builder.rb`
- `app/models/report.rb`
- `app/models/order_service.rb`
- `app/models/budget.rb`
- `app/models/service_item.rb`

## Regras De Negócio

- Faturamento operacional de OS deve usar `quantity * unit_price`.
- Área financeira do gestor deve ser escopada pela empresa atual.
- Status de OS e orçamento determinam indicadores de realizado, pendente,
  cancelado, aberto ou aprovado.
- Filtros por período devem deixar claro qual coluna de data está sendo usada.

## Estados E Transições

- OS finalizada geralmente compõe realizado operacional.
- OS aberta, pendente, agendada, em andamento, concluída ou atrasada pode
  compor pendências dependendo da tela.
- Orçamentos aprovados, rejeitados e abertos alimentam métricas distintas.

## Riscos Comuns

- Misturar receita operacional do cliente com MRR da plataforma.
- Somar `unit_price` sem quantidade.
- Contar duplicado ao usar joins com técnicos ou itens.
- Perder `distinct` em relatórios por técnico.
- Gerar exportação sem escopo por empresa.

## Testes Recomendados

- Testes de dashboard e financeiro com múltiplos itens por OS.
- Testes de relatórios com filtros por data, status e técnico.
- Testes de exportação CSV.
- Testes com duas empresas para validar isolamento.
