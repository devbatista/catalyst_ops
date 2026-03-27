# CatalystOps - README Tecnico

Este documento e voltado para desenvolvimento, manutencao e troubleshooting do
projeto. Ele complementa o `README.md` da raiz com foco em arquitetura
aplicacional, boundaries de dominio, autorizacao, background jobs e
particularidades do workspace.

## Visao arquitetural

O CatalystOps e uma aplicacao Ruby on Rails com modelo SaaS multi-tenant,
orientada a empresas prestadoras de servicos tecnicos. O tenant primario e
`Company`, e a maior parte da modelagem de negocio deriva desse isolamento.

Pilares tecnicos do projeto:

- Ruby on Rails como framework MVC
- PostgreSQL como datastore transacional
- Redis como backend de fila e cache
- Sidekiq para processamento assíncrono
- Devise para autenticacao
- CanCanCan para autorizacao
- Active Storage para anexos
- Action Mailer para notificacoes transacionais

## Topologia logica

O sistema e segmentado por subdominios, cada um com responsabilidade clara:

- `register`: onboarding, criacao de empresa e assinatura inicial
- `login`: autenticacao e recuperacao de credenciais
- `app`: area operacional da empresa
- `admin`: backoffice da plataforma
- `webhook`: entrada de callbacks externos

Essa separacao ajuda a preservar coesao de contexto e reduz acoplamento entre
fluxos de onboarding, operacao e administracao global.

## Modelo de tenancy

O tenancy e implementado em nivel aplicacional, principalmente por escopo de
`company_id`. Em termos praticos:

- `User` pertence a uma `Company`
- `Client` pertence a uma `Company`
- `OrderService` pertence a `Client` e `Company`
- `SupportTicket` pertence a `Company`
- `Subscription` pertence a `Company`

Regra operacional importante:

- sempre que a consulta estiver em contexto de app, o filtro por empresa deve
  ser explicito ou derivado do relacionamento do `current_user`
- qualquer query "global" em controllers da area `app` deve ser tratada como
  suspeita ate prova em contrario

## Camadas e namespaces

O projeto esta organizado em dois namespaces principais de interface:

- `App::...`: contexto de empresa usuaria
- `Admin::...`: contexto administrativo da plataforma

Dentro de `app/controllers/app`, o comportamento e role-aware:

- `gestor`
- `tecnico`

O roteamento e separado em arquivos por area, por exemplo:

- [`config/routes/app.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/config/routes/app.rb)
- [`config/routes/admin.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/config/routes/admin.rb)

## Autenticacao e autorizacao

### Autenticacao

O projeto usa Devise. O `current_user` e o principal entrypoint de contexto.
Praticamente todo fluxo protegido depende de:

- usuario autenticado
- role valida
- `company_id` consistente

### Autorizacao

As permissoes sao centralizadas em [`app/models/ability.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/models/ability.rb).

Esse arquivo concentra a matriz RBAC/ABAC da aplicacao. Os principais vetores de
decisao sao:

- role do usuario (`admin`, `gestor`, `tecnico`)
- escopo por empresa
- ownership da entidade
- relacionamento indireto, por exemplo tecnico vendo apenas OS atribuidas

Padrao esperado:

- regras globais por role ficam em metodos dedicados
- controllers usam `authorize!` ou `load_and_authorize_resource`
- views escondem acoes nao autorizadas, mas a regra real precisa estar no backend

## Dominios funcionais principais

### 1. Empresa e assinatura

`Company` e o agregado raiz de tenancy. Ela centraliza:

- usuarios
- clientes
- ordens de servico
- tickets
- assinatura corrente

`Subscription` modela o estado comercial do cliente SaaS. Alguns comportamentos
de produto dependem diretamente do plano corrente, como:

- limite de tecnicos
- limite de ordens de servico
- nivel de suporte

### 2. Usuarios e papeis

`User` suporta papeis distintos no mesmo sistema:

- `gestor`: opera a empresa
- `tecnico`: executa ordens de servico
- `admin`: opera a plataforma

O sistema tambem usa semantica como `can_be_technician`, o que exige cuidado na
leitura das regras de negocio e nos filtros de consulta.

### 3. Clientes

`Client` representa o cliente final da empresa operadora. O relacionamento com
`OrderService` e central para o fluxo operacional.

### 4. Ordens de servico

`OrderService` e um dos aggregates centrais do sistema. Ela concentra:

- cliente
- empresa
- tecnicos vinculados via `Assignment`
- itens de servico
- anexos
- transicoes de status
- disparos de notificacao por email

Enum de status atual:

- `pendente`
- `agendada`
- `em_andamento`
- `concluida`
- `cancelada`
- `finalizada`
- `atrasada`

Esse lifecycle impacta:

- dashboards
- notificacoes
- regras de edicao
- visibilidade de acoes
- calculos operacionais e financeiros

### 5. Atribuicao de tecnicos

`Assignment` faz o binding entre `User` tecnico e `OrderService`.

Esse model encapsula validacoes importantes:

- usuario atribuido deve ser tecnico
- nao pode haver sobreposicao indevida de janela operacional
- nao se deve atribuir tecnico em status nao permitidos

Tambem e um ponto de fan-out de notificacao para tecnicos.

### 6. Itens de servico

`ServiceItem` compoe o valor operacional de cada OS. Sempre que houver calculo
de valor agregado, o baseline correto e:

`quantity * unit_price`

Evite somar apenas `unit_price`, pois isso subestima o total quando a
quantidade for maior que 1.

### 7. Suporte e base de conhecimento

`SupportTicket` e `SupportMessage` cobrem o fluxo de suporte conversacional.

`KnowledgeBaseArticle` cobre artigos de ajuda e agora suporta segregacao por
audiencia via campo `audience`, tipicamente:

- `gestor`
- `tecnico`

## Dashboards por role

### Dashboard de gestor

Foco em indicadores de operacao da empresa:

- clientes
- tecnicos
- volume de OS
- faturamento bruto operacional
- ordens recentes
- distribuicao por status

O "faturamento bruto" no dashboard de gestor e um indicador operacional,
derivado da soma dos itens de servico, nao um fluxo de caixa contabil.

### Dashboard de tecnico

Foco em execucao:

- agenda do dia
- OS em andamento
- OS atrasadas
- concluidas no mes
- proximas visitas
- atribuicoes correntes
- pendentes de finalizacao

Esse dashboard usa um recorte de `OrderService` filtrado pelas OS atribuidas ao
`current_user`.

### Dashboard de admin

Foco em saude da plataforma:

- empresas ativas
- assinaturas ativas
- MRR estimado
- tickets abertos
- novas empresas no mes
- usuarios no mes
- OS finalizadas no mes
- assinaturas em atencao

Boa pratica adotada recentemente:

- mover `where` e agregacoes repetidas para scopes/metodos nos models
- manter controller fino e sem query ad hoc demais

## Regras especificas para tecnico

O papel `tecnico` possui um conjunto de restricoes operacionais relevantes:

- pode ver apenas OS associadas a ele
- nao acessa tickets de suporte
- acessa a base de conhecimento via submenu de suporte
- tem dashboard dedicado
- pode editar apenas subconjunto controlado da OS

Na tela de edicao de OS:

- campos estruturais ficam visiveis, mas `disabled`
- o backend aceita apenas os atributos autorizados
- `attachments` e `observations` sao o foco principal de update

Em OS atrasada:

- apenas `gestor` pode reagendar
- tecnico nao deve conseguir burlar isso via URL direta

## Area financeira

A area `Financeira` foi modelada como um modulo operacional para gestor,
baseado no valor dos itens de servico por status da OS.

Semantica atual:

- `Faturamento Realizado`: OS `finalizada`
- `Faturamento Pendente`: OS `pendente`, `agendada`, `em_andamento`,
  `concluida`, `atrasada`
- `cancelada` fica fora do calculo

Isso nao e fluxo de caixa contabil. E uma leitura operacional de backlog e
receita consolidada sobre o agregado `OrderService`.

## Background jobs e assincronia

O projeto usa Sidekiq para execucao assíncrona, principalmente em:

- envio de emails
- eventos de notificacao

### Variaveis de ambiente de reconciliacao

Os jobs de assinaturas usam janelas de tempo para reduzir custo de chamadas ao
gateway e limitar o volume processado por execucao.

- `SUBSCRIPTIONS_RECONCILIATION_WINDOW_DAYS`
  Controla a janela (em dias) do
  `Subscriptions::ReconcileSubscriptionsJob`.
  Valor padrao: `30`.
- `SUBSCRIPTIONS_PENDING_REPROCESS_WINDOW_DAYS`
  Controla a janela (em dias) do
  `Subscriptions::ReprocessPendingPaymentsJob`.
  Valor padrao: `30`.

Se as variaveis estiverem ausentes, vazias, `0` ou negativas, os jobs usam
fallback para `30` dias.

### Variaveis de ambiente de retencao de auditoria

O job `Audit::CleanupEventsJob` aplica a politica de retencao em `audit_events`
no modo hot-only, removendo registros antigos em lotes.

- `AUDIT_LOG_RETENTION_DAYS`
  Janela de retencao em dias para `audit_events`.
  Valor padrao: `180`.
- `AUDIT_LOG_CLEANUP_BATCH_SIZE`
  Quantidade de registros por lote durante a limpeza.
  Valor padrao: `1000`.
- `AUDIT_LOG_CLEANUP_DRY_RUN`
  Quando `true`, nao remove dados; apenas mede quantos seriam removidos.
  Valor padrao: `false`.

## Auditoria global (base)

Foi adicionada a base de auditoria em tabela dedicada:

- `audit_events`

Campos principais:

- `occurred_at`, `action`, `source`
- `actor_type`, `actor_id`
- `company_id`
- `resource_type`, `resource_id`
- `request_id`, `ip_address`, `user_agent`
- `metadata` (`jsonb`)

Para registrar eventos de forma padronizada, usar:

- `Audit::EventLogger.call(...)`

Catalogo inicial de acoes:

- autenticacao: `auth.*`
- usuarios/tecnicos: `user.*` e `technician.*`
- clientes: `client.*`
- ordens de servico: `order_service.*`
- cupons: `coupon.*`
- assinaturas/pagamentos: `subscription.*`
- webhooks: `webhook.*`
- sistema/jobs: `job.*` e `system.*`

Padrao de nome:

- `<dominio>.<evento>[.<subevento>]`
- exemplos: `order_service.status.changed`, `webhook.signature.invalid`

As acoes validas ficam centralizadas em:

- `Audit::ActionCatalog::ALL`
- arquivo: [`app/services/audit/action_catalog.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/services/audit/action_catalog.rb)

Toda vez que aparecer `deliver_later`, o fluxo real passa por:

1. serializacao do job
2. persistencia/logica da fila no Redis
3. consumo pelo processo `sidekiq`
4. reidratacao de argumentos, inclusive `GlobalID`
5. execucao do mailer

Isso significa que erros em mailers podem aparecer tardiamente, fora da
request original.

## Action Mailer e notificacoes de OS

`OrderService` possui callbacks que disparam emails transacionais em eventos de
mudanca de estado.

Exemplos:

- criacao
- agendamento
- inicio de atendimento
- conclusao
- finalizacao
- atraso

### Inconsistencia conhecida em `notify_create`

No estado atual do codigo:

- `OrderServiceMailer#notify_create` define `@order_service` e `@client`
- o destinatario e `@client.email`
- o template texto usa `@client.name`
- o template HTML ainda referencia `@gestor.name`

Consequencia:

- o job pode falhar com `undefined method 'name' for nil`
- o erro aparece em log do Sidekiq como `ActionView::Template::Error`

Quando o log mostra:

- `Performing ActionMailer::MailDeliveryJob`
- `Rendered order_service_mailer/notify_create.html.erb`

isso significa que o worker retirou o job da fila e iniciou a renderizacao. So
ha garantia real de sucesso quando o job conclui sem `WARN` ou `ERROR`
subsequente.

## Seeds e bootstrap de dados

O bootstrap usa carga ordenada por ambiente:

- `db/seeds/common`
- `db/seeds/development`
- `db/seeds/production`

O seed de preparacao limpa a base antes de repopular. Como existem varias FKs,
foi necessario usar `disable_referential_integrity` para evitar violacoes
durante `delete_all`.

Pontos relevantes do dataset de desenvolvimento:

- empresas
- usuarios
- clientes
- ordens de servico
- atribuicoes
- itens de servico
- artigos de base de conhecimento
- tickets e mensagens de suporte

## Base de conhecimento

Os artigos markdown em `docs/gestor` e `docs/tecnico` servem como fonte para a
base de conhecimento exibida no app.

Implicacoes tecnicas:

- a estrutura de pastas vira categoria semantica
- o `seed` transforma markdown em HTML
- o campo `audience` segmenta artigos por papel

Isso cria um fluxo hibrido:

- markdown versionado em repositório
- conteudo indexado em banco
- renderizacao filtrada por role no app

## Convencoes recomendadas

### Querying

- prefira scopes expressivos no model
- evite `where` repetitivo em controllers
- preserve scoping por empresa
- cuidado com `joins + distinct + order` no PostgreSQL

### Autorizacao

- regra de permissao sempre no backend
- view apenas reflete o estado autorizado
- paths sensiveis devem ser protegidos contra acesso direto

### Calculo de valores

- para total de itens, use `quantity * unit_price`
- para leitura financeira, explicite se o valor e previsto ou realizado
- nao chame de fluxo de caixa algo que nao modele entrada e saida real

### Seeds

- mantenha ordenacao lexical previsivel
- se um seed depender de outro, o nome do arquivo precisa refletir isso
- ex.: `9-support_tickets.rb` antes de `9a-support_messages.rb`

## CI/CD e governanca de merge

### Pipeline de deploy

O deploy automatizado roda via GitHub Actions em
[` .github/workflows/deploy.yml `](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/.github/workflows/deploy.yml),
executando [`bin/deploy`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/bin/deploy) no servidor.

Detalhe operacional importante:

- o workflow executa `bash /opt/catalyst_ops/bin/deploy` (sem `chmod`)
- isso evita alterar permissao do arquivo no servidor e sujar `git status`

Fluxo tecnico relevante:

- `git fetch` + diff de arquivos alterados para calcular plano de deploy
- rebuild de imagem quando houver mudancas sensiveis (ex.: `db/migrate/*`,
  `app/*`, `config/*`, `lib/*`, dependencias e dockerfiles)
- restart de `web`/`sidekiq` quando necessario
- `db:migrate` executado via `docker compose run --rm web ...` para aplicar
  pendencias

Importante para troubleshooting:

- producao nao usa bind mount de codigo no `web`; o codigo em runtime vem da
  imagem Docker
- sem rebuild, migration nova pode existir no host git mas nao no container
- se isso ocorrer, o `db:migrate` nao enxerga o arquivo da migration

### Politica de janela para PRs

A politica de janela esta em
[` .github/workflows/policy-window.yml `](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/.github/workflows/policy-window.yml).

Regras implementadas:

- mudancas sensiveis: somente `22:00-06:00` (America/Sao_Paulo)
- mudancas simples: somente `09:00-18:00` (America/Sao_Paulo)
- PR com migration deve conter apenas `db/migrate/*` e opcionalmente
  `db/schema.rb`

Observacao:

- o workflow bloqueia merge via check; para aplicacao real, Branch Protection da
  `main` deve exigir o status check `PR Window Policy / merge_window_policy`
- como o check e avaliado no momento da execucao do job, para politica de hora
  estrita no instante do merge recomenda-se habilitar `Require branches to be
  up to date before merging` na `main` ou usar merge queue (`merge_group`) para
  revalidacao no fluxo final de merge

## Pontos de atencao

### Scope global enganoso

Qualquer scope com `limit(1)` em model compartilhado deve ser revisado com
cuidado. Em especial quando a intencao de negocio for "um registro por empresa"
e nao "um registro global".

### Integridade de assinatura

Se a regra de negocio for "uma unica assinatura ativa por empresa", isso deve
ser sustentado nao apenas pela aplicacao, mas idealmente por restricao de banco
ou pelo menos por validacao consistente.

### SQL ambiguo

Em relacoes com `includes`, `joins` e ordenacao por colunas comuns como
`updated_at`, qualifique explicitamente a tabela:

- `order_services.updated_at`
- `order_services.finished_at`
- `order_services.started_at`

### Distinct com order no PostgreSQL

`SELECT DISTINCT` combinado com `ORDER BY` em expressoes nao selecionadas pode
quebrar. Se isso aparecer, revise:

- necessidade real de `distinct`
- expressao usada no `order`
- possibilidade de qualificar e simplificar a query

## Referencias rapidas

- [`README.md`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/README.md)
- [`app/models/ability.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/models/ability.rb)
- [`app/models/order_service.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/models/order_service.rb)
- [`app/models/company.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/models/company.rb)
- [`app/models/subscription.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/models/subscription.rb)
- [`app/controllers/app/dashboard_controller.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/controllers/app/dashboard_controller.rb)
- [`app/controllers/admin/dashboard_controller.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/controllers/admin/dashboard_controller.rb)
- [`app/controllers/app/support_controller.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/controllers/app/support_controller.rb)
- [`app/mailers/order_service_mailer.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/mailers/order_service_mailer.rb)
- [`docs/gestor`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docs/gestor)
- [`docs/tecnico`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docs/tecnico)

## Nota final para manutencao

Se voce for mexer em fluxos sensiveis deste projeto, revise sempre estes eixos:

- tenant isolation por `company_id`
- matrix de permissao em `Ability`
- lifecycle de `OrderService`
- side effects assíncronos no Sidekiq
- consistencia entre controller, model, view e mailer
