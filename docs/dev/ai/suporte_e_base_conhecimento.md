# Suporte E Base De Conhecimento

## Quando Ler Este Arquivo

Leia antes de alterar tickets, mensagens, anexos de suporte, base de
conhecimento, artigos, audiência ou fluxos de contato rápido.

## Visão Geral

O suporte combina tickets conversacionais por empresa com uma base de
conhecimento segmentada por audiência. Gestores e técnicos podem consumir
conteúdos diferentes.

## Areas Relacionadas

- `app/gestor`: abre, acompanha e responde tickets; consulta artigos.
- `app/tecnico`: consulta artigos e usa suporte conforme permissão.
- `admin`: gerência tickets, mensagens e artigos.

## Pontos De Entrada Importantes

- `app/models/support_ticket.rb`
- `app/models/support_message.rb`
- `app/models/knowledge_base_article.rb`
- `app/controllers/app/support_tickets_controller.rb`
- `app/controllers/app/support_messages_controller.rb`
- `app/controllers/app/knowledge_base_controller.rb`
- `app/controllers/admin/knowledge_base_articles_controller.rb`
- `app/services/support_ticket_notifications.rb`

## Regras De Negócio

- Ticket pertence a uma `Company` e a um `User`.
- Mensagens pertencem ao ticket e usuário remetente.
- Artigos de base de conhecimento possuem `audience`, como `gestor` e
  `tecnico`.
- Anexos devem permanecer ligados ao ticket ou mensagem correta.
- Admin pode operar suporte global; área `app` deve preservar tenant.

## Estados E Transições

- Tickets possuem status, categoria, impacto e prioridade.
- Respostas devem atualizar ordenação por atividade recente quando aplicável.
- Artigos podem ser filtrados por audiência.

## Riscos Comuns

- Expor ticket de outra empresa.
- Mostrar artigo de audiência errada.
- Perder anexos ao mover mensagens ou tickets.
- Notificar usuário incorreto em respostas de suporte.

## Testes Recomendados

- Testes de tickets e mensagens por empresa.
- Testes de anexos em tickets e mensagens.
- Testes de filtro de artigos por audiência.
- Testes de notificações de suporte.
