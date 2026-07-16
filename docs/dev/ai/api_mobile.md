# API Mobile

## Quando Ler Este Arquivo

Leia antes de alterar a API mobile (subdomínio `mobile`, namespace `/v1`),
autenticação por token Bearer, sessões de API, payloads JSON, paginação,
mapeamento de status ou anexos enviados pelo app.

## Visão Geral

A API mobile é uma API JSON servida sob o subdomínio `mobile` no caminho
`/v1`, com controllers em `Mobile::V1` herdando de `ActionController::API`.
A autenticação usa token Bearer opaco persistido em `MobileApiSession`
(apenas o `token_digest` SHA-256 é armazenado). Todas as consultas de OS são
escopadas à empresa do usuário e às OS em que ele é técnico atribuído.

## Áreas Relacionadas

- `config/routes/mobile.rb`: rotas sob `constraints subdomain: "mobile"`.
- `MobileApiSession`: emissão, validação, expiração e revogação de tokens.
- Auditoria: eventos `mobile.api.*` via `Audit::Log` com `source: "mobile"`
  (valor válido em `AuditEvent::SOURCES`).
- `OrderService`, `Budget`, `ServiceItem`, `Client`: dados expostos.

## Pontos De Entrada Importantes

- `config/routes/mobile.rb`
- `app/controllers/mobile/v1/base_controller.rb`
- `app/controllers/mobile/v1/auth_controller.rb`
- `app/controllers/mobile/v1/health_controller.rb`
- `app/controllers/mobile/v1/users_controller.rb`
- `app/controllers/mobile/v1/dashboard_controller.rb`
- `app/controllers/mobile/v1/agenda_controller.rb`
- `app/controllers/mobile/v1/order_services_controller.rb`
- `app/controllers/mobile/v1/budgets_controller.rb`
- `app/models/mobile_api_session.rb`

## Regras De Negócio

- Endpoints e retornos:
  - `GET /v1/health`: status do serviço, sem autenticação.
  - `POST /v1/auth/login`: valida email/senha (Devise `valid_password?`),
    exige usuário ativo e `access_enabled?`; retorna `accessToken`/`token`,
    `token_type: "Bearer"`, `expires_at` e payload do usuário.
  - `GET /v1/auth/me` e `GET /v1/users/me`: payload do usuário autenticado
    (id, nome, email, telefone formatado, papel com rótulo pt-BR, iniciais,
    empresa).
  - `DELETE /v1/auth/logout`: revoga a sessão atual (`revoke!`).
  - `DELETE /v1/auth/logout_all`: revoga todas as sessões ativas do usuário.
  - `GET /v1/mobile/dashboard`: métricas (OS abertas, visitas hoje,
    atrasadas, concluídas), próximas 5 visitas, breakdown por status e 5 OS
    recentes.
  - `GET /v1/mobile/agenda`: OS agendadas no intervalo `start_date`/`end_date`
    (padrão: mês corrente), ordenadas por `scheduled_at`.
  - OS: `index`/`show`/`update` disponíveis em duas rotas equivalentes,
    `/v1/order_services` e `/v1/mobile/service_orders` (mesmo controller).
    `index` aceita filtros `status` e `date` (ISO 8601) e é paginado;
    `show`/`update` retornam payload detalhado (anexos, itens, financeiro).
  - `GET /v1/budgets` e `GET /v1/budgets/:id`: orçamentos da empresa,
    somente leitura, com filtro `status` validado contra `Budget.statuses`.
- Ciclo de vida do token: emitido no login com TTL de 30 dias
  (`end_of_day`), token bruto de 32 bytes hex retornado uma única vez; só o
  SHA-256 (`token_digest`) é persistido. A cada requisição autenticada,
  `last_used_at` é atualizado. Sessão é válida se `revoked_at` for nulo e
  `expires_at` futuro (scope `active`).
- Toda requisição autenticada revalida `user.active?` e
  `user.access_enabled?`, além do token.
- Escopo de dados: dashboard, agenda e OS usam
  `mobile_company.order_services.by_technician(current_mobile_user.id)`,
  ou seja, sempre limitados à empresa do usuário e às OS em que ele está
  atribuído como técnico — não há tratamento diferenciado por papel
  (gestor/admin também só veem OS às quais estão atribuídos). Orçamentos
  são escopados apenas por empresa (`mobile_company.budgets`), sem filtro
  por atribuição.
- `order_services#update` permite apenas `status`, `notes`/`observations`
  (ambos gravam em `observations`) e `attachments` (anexados via Active
  Storage após o save).
- i18n de status: a API expõe `status` (chave em inglês, ex.
  `in_progress`), `statusKey` (enum interno, ex. `em_andamento`) e
  `statusLabel` (rótulo pt-BR). Filtros de entrada aceitam ambas as formas
  via `normalize_mobile_status` (remove acentos e normaliza).
- Paginação: `page`/`per` (padrão 20, máximo 100), resposta com `data` e
  `meta` (`current_page`, `total_pages`, `total_count`, `per_page`).
- Auditoria: `with_mobile_current_context` define `Current.source =
  "mobile"`; login/logout usam `Audit::AuthLogger` e demais ações registram
  eventos `mobile.api.*` (listagem, visualização, atualização).
- Valores monetários são expostos em centavos (`*Cents`) e como rótulo
  formatado `R$ x,yy`.

## Estados E Transições

- `MobileApiSession`: ativa (sem `revoked_at`, `expires_at` futuro) →
  revogada (logout/logout_all) ou expirada (TTL de 30 dias).
- Status de OS seguem o enum de `OrderService` (`pendente`, `agendada`,
  `em_andamento`, `concluida`, `finalizada`, `cancelada`, `atrasada`),
  traduzidos para chaves em inglês no payload.
- Prioridade no payload é derivada: `Alta` se atrasada, `Média` se agendada
  para até 1 dia, senão `Normal`.
- Erros de autenticação: 401 (token ausente/inválido/expirado, credenciais
  inválidas), 403 (usuário inativo ou empresa com acesso desativado),
  404 JSON para registro não encontrado, 422 para falha de validação no
  update.

## Riscos Comuns

- Vazar o token bruto em logs — só o digest deve ser persistido.
- Esquecer de revalidar `active?`/`access_enabled?` ao mudar autenticação.
- Quebrar o escopo `by_technician` ou o escopo por empresa e expor OS de
  outra empresa ou de outro técnico.
- Divergência entre `mobile_status_key`/`mobile_status_label`/
  `normalize_mobile_status` ao adicionar novo status de OS.
- Alterar uma das duas rotas de OS (`order_services` vs
  `mobile/service_orders`) e esquecer a outra — ambas usam o mesmo
  controller.
- Permitir campos extras no `update` sem revisar `params.permit`.
- Esquecer `Current.source = "mobile"` e registrar auditoria com source
  errado.

## Testes Recomendados

- Testes de request para login (sucesso, credenciais inválidas, usuário
  inativo, empresa desativada) e ciclo do token (expiração, revogação,
  logout_all). Hoje não existem specs para `mobile` em `spec/` — criar ao
  alterar a API.
- Testes de escopo: técnico de outra empresa ou não atribuído não acessa a
  OS; orçamentos limitados à empresa.
- Testes de `order_services#update` com status em inglês/português, notas e
  anexos.
- Testes de paginação (`page`/`per`, limite de 100) e filtros
  (`status`, `date`, `start_date`/`end_date`).
- Testes de auditoria verificando eventos `mobile.api.*` com
  `source: "mobile"`.
