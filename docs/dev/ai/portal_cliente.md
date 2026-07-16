# Portal do Cliente

## Quando Ler Este Arquivo

Leia antes de alterar o fluxo público de aprovação de orçamento pelo cliente
final: rotas do subdomínio `cliente`, acesso por token, aprovação, rejeição,
PDF ou e-mails relacionados.

## Visão Geral

O portal do cliente é a área pública, no subdomínio `cliente`, onde o cliente
final acessa um orçamento por link assinado (token), revisa itens e valores,
baixa o PDF e aprova ou rejeita. A aprovação cria a OS automaticamente e
notifica os gestores por e-mail.

## Áreas Relacionadas

- `app/gestor`: envia o orçamento para aprovação e gera o token.
- `cliente`: página pública de aprovação/rejeição e download de PDF.
- Orçamentos e OS: aprovação converte o orçamento em ordem de serviço.
- Mailers: entrega do link ao cliente e notificação de OS criada ao gestor.

## Pontos De Entrada Importantes

- `config/routes/cliente.rb`
- `app/controllers/cliente/budget_approvals_controller.rb`
- `app/views/cliente/budget_approvals/show.html.erb`
- `app/models/budget.rb`
- `app/commands/cmd/budgets/approve_and_create_order_service.rb`
- `app/mailers/budget_mailer.rb`

## Regras De Negócio

- As rotas exigem subdomínio `cliente` e carregam o orçamento pelo `:token`
  na URL: `show`, `generate_pdf` (GET) e `approve`, `reject` (PATCH).
- O controller pula autenticação, checagem de autorização, bloqueio de
  empresa inativa e aceite de termos; usa layout `public`.
- O token é um `signed_id` com propósito `:budget_approval` e expiração
  (por padrão o fim do dia de `valid_until` ou 1 semana). Token inválido ou
  expirado retorna 404 com "Link inválido ou expirado."
- `send_for_approval` (gestor) só ocorre para orçamento `rascunho` ou
  `rejeitado`, tem throttle de 5 minutos e envia
  `BudgetMailer.approval_request_to_client` com a URL de aprovação no
  subdomínio `cliente`.
- Aprovar chama `approve_and_create_order_service!(approver_role: :cliente)`;
  se `approved_at` já está preenchido, apenas redireciona com aviso de que já
  foi aprovado.
- `Cmd::Budgets::ApproveAndCreateOrderService` roda com `with_lock`, é
  idempotente (retorna a OS existente se o orçamento já tem
  `order_service_id`), marca o orçamento como `aprovado`, cria a OS com
  status `pendente` copiando os itens de serviço, garante auditoria de
  `order_service.created` e notifica os gestores por e-mail
  (`notify_manager_order_service_created`), com fallback para o responsável
  da empresa.
- Rejeitar exige motivo (`rejection_reason` não pode ficar em branco) e marca
  `rejeitado` com `rejected_at`; se `rejected_at` já está preenchido, apenas
  redireciona com aviso.
- `generate_pdf` gera o PDF via `Cmd::Pdf::CreateBudget` e envia como
  download `orcamento_<code>.pdf`.

## Estados E Transições

- `Budget.statuses`: `rascunho`, `enviado`, `aprovado`, `rejeitado`,
  `cancelado`.
- Aprovação é permitida a partir de `rascunho`, `enviado`, `rejeitado` ou
  `aprovado`; rejeição a partir de `rascunho`, `enviado` ou `rejeitado`.
- `send_for_approval!` muda para `enviado` e limpa `approved_at`,
  `rejected_at` e `rejection_reason`.
- A view pública decide o que mostrar por `approved_at`/`rejected_at`: alerta
  de já aprovado, alerta de rejeitado (com motivo) ou os botões de resposta.

## Riscos Comuns

- Quebrar links já enviados ao mudar propósito, expiração ou lookup do token.
- Reintroduzir autenticação/autorização nas rotas públicas e derrubar o fluxo
  externo.
- Permitir que um orçamento gere mais de uma OS (o comando usa lock e
  idempotência por `order_service_id`).
- Gerar URLs sem o subdomínio `cliente` em redirects, mailer ou views.
- Vazar dados de outra empresa na página pública (o token dá acesso apenas ao
  orçamento assinado).

## Testes Recomendados

- Testes de request do fluxo público: show, PDF, aprovação e rejeição com
  token válido, inválido e expirado.
- Testes de idempotência: aprovar duas vezes não cria segunda OS.
- Testes de rejeição sem motivo (deve falhar) e com motivo.
- Testes do mailer: link de aprovação ao cliente e notificação de OS criada
  aos gestores (com fallback para o responsável).
