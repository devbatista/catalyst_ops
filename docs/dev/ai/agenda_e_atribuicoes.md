# Agenda E Atribuições

## Quando Ler Este Arquivo

Leia antes de alterar agenda, atribuição de técnico, conflitos de horário,
visão de calendário ou notificações de atendimento.

## Visão Geral

`Assignment` liga técnicos a ordens de serviço. A agenda deriva principalmente
das OS agendadas e das atribuições, respeitando empresa, role e janelas de
atendimento.

## Áreas Relacionadas

- `app/gestor`: agenda geral, agenda por técnico e atribuição.
- `app/tecnico`: agenda própria e OS atribuídas.
- Jobs/notificações: avisos de atribuição e atendimento.

## Pontos De Entrada Importantes

- `app/models/assignment.rb`
- `app/models/order_service.rb`
- `app/models/user.rb`
- `app/controllers/app/calendar_controller.rb`
- `app/controllers/app/technicians_controller.rb`
- `app/controllers/app/order_services_controller.rb`

## Regras De Negócio

- Usuário atribuído deve poder atuar como técnico.
- O mesmo técnico não deve ser atribuído duas vezes à mesma OS.
- Atribuições devem respeitar status permitidos da OS.
- Agenda de técnico deve mostrar apenas atendimentos autorizados.
- Conflitos de janela operacional devem ser tratados de forma explícita.

## Estados E Transições

- Atribuições ativas ignoram OS concluídas ou canceladas.
- Mudanças em `scheduled_at`, `expected_end_at` e status da OS afetam a agenda.

## Riscos Comuns

- Permitir sobreposição indevida de horário.
- Mostrar agenda de outro tenant.
- Considerar apenas role `tecnico` e esquecer `can_be_technician`.
- Remover técnico sem lidar com atribuições existentes.

## Testes Recomendados

- Testes de model para unicidade e elegibilidade de técnico.
- Testes de agenda com gestor e técnico.
- Testes de conflito de horário e reagendamento.
- Testes com duas empresas.
