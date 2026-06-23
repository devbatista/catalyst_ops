# Ordens De Serviço

## Quando Ler Este Arquivo

Leia antes de alterar OS, status de atendimento, anexos, itens de serviço,
PDFs, dashboards operacionais, notificações de OS ou regras de edição.

## Visão Geral

`OrderService` é um dos agregados centrais do sistema. Ele conecta empresa,
cliente, técnicos, agenda, itens, anexos, status operacional e indicadores.

## Áreas Relacionadas

- `app/gestor`: cria, edita, agenda, cancela, finaliza e acompanha OS.
- `app/tecnico`: visualiza e atualiza OS atribuídas.
- `admin`: consulta e suporte operacional.
- Jobs: marcação de atraso e notificações.

## Pontos De Entrada Importantes

- `app/models/order_service.rb`
- `app/models/service_item.rb`
- `app/models/order_service_received_item.rb`
- `app/models/assignment.rb`
- `app/controllers/app/order_services_controller.rb`
- `app/controllers/app/order_services/service_items_controller.rb`
- `app/services/pdf_generator.rb`

## Regras De Negócio

- Toda OS pertence a uma `Company` e a um `Client`.
- Código de OS deve ser único dentro da empresa.
- Valor agregado deve considerar `quantity * unit_price`.
- Técnico só deve acessar OS atribuída ou autorizada pela role.
- Anexos e comprovantes devem continuar vinculados a OS correta.
- Mudanças de status impactam dashboards, financeiro, relatórios e ações
  disponíveis.

## Estados E Transições

- Status conhecidos: `pendente`, `agendada`, `em_andamento`, `concluida`,
  `cancelada`, `finalizada`, `atrasada`.
- Campos de agenda, início, conclusão e fim esperado devem permanecer coerentes
  com o status.
- OS atrasada deriva de agendamento vencido e influencia filtros operacionais.

## Riscos Comuns

- Somar `unit_price` sem multiplicar por `quantity`.
- Permitir edição em status que deveria estar fechado.
- Perder escopo por empresa em filtros, busca ou exportação.
- Quebrar atribuições ao remover usuários ou alterar status.
- Gerar PDF com dados incompletos ou de outra empresa.

## Testes Recomendados

- Testes de model para validações, status e cálculos de total.
- Testes de controller/request para gestor e técnico.
- Testes de anexos, itens de serviço e recebimento/devolução de produtos.
- Testes de dashboard, financeiro e relatórios que dependem de status de OS.
