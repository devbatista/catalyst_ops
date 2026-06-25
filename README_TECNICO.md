# CatalystOps - README Técnico

Este documento é voltado para desenvolvimento, manutenção e troubleshooting do
projeto. Ele complementa o `README.md` da raiz com foco em arquitetura
aplicacional, boundaries de domínio, autorização, background jobs e
particularidades do workspace.

## Documentação para agentes de IA

O repositório possui documentação neutra para agentes de IA:

- [`AGENTS.md`](AGENTS.md): ponto de entrada com regras gerais.
- [`docs/dev/ai/00_indice.md`](docs/dev/ai/00_indice.md): índice de contexto
  por domínio.

Antes de alterar fluxos sensíveis, leia o arquivo de domínio correspondente em
`docs/dev/ai/`. Essa documentação complementa este README técnico com regras de
negócio, riscos comuns e testes recomendados por área.

## Visão arquitetural

O CatalystOps é uma aplicação Ruby on Rails com modelo SaaS multi-tenant,
orientada a empresas prestadoras de serviços técnicos. O tenant primário é
`Company`, e a maior parte da modelagem de negócio deriva desse isolamento.

Pilares técnicos do projeto:

- Ruby on Rails como framework MVC
- PostgreSQL como datastore transacional
- Redis como backend de fila e cache
- Sidekiq para processamento assíncrono
- Devise para autenticação
- CanCanCan para autorização
- Active Storage para anexos
- Action Mailer para notificações transacionais
- Mercado Pago para assinaturas e pagamentos
- Sentry para monitoramento de erros
- Auditoria global em `audit_events`

## Topologia lógica

O sistema é segmentado por subdomínios, cada um com responsabilidade clara:

- `register`: onboarding, criação de empresa e assinatura inicial
- `login`: autenticação e recuperação de credenciais
- `app`: área operacional da empresa
- `admin`: backoffice da plataforma
- `webhook`: entrada de callbacks externos

Essa separação ajuda a preservar coesão de contexto e reduz acoplamento entre
fluxos de onboarding, operação e administração global.

## Modelo de tenancy

O tenancy é implementado em nível aplicacional, principalmente por escopo de
`company_id`. Em termos práticos:

- `User` pertence a uma `Company`
- `Client` pertence a uma `Company`
- `OrderService` pertence a `Client` e `Company`
- `SupportTicket` pertence a `Company`
- `Subscription` pertence a `Company`

Regra operacional importante:

- sempre que a consulta estiver em contexto de app, o filtro por empresa deve
  ser explícito ou derivado do relacionamento do `current_user`
- qualquer query "global" em controllers da área `app` deve ser tratada como
  suspeita até prova em contrário

## Camadas e namespaces

O projeto está organizado em dois namespaces principais de interface:

- `App::...`: contexto de empresa usuária
- `Admin::...`: contexto administrativo da plataforma

Dentro de `app/controllers/app`, o comportamento é role-aware:

- `gestor`
- `tecnico`

O roteamento é separado em arquivos por área, por exemplo:

- [`config/routes/app.rb`](config/routes/app.rb)
- [`config/routes/admin.rb`](config/routes/admin.rb)

## Autenticação e autorização

### Autenticação

O projeto usa Devise. O `current_user` é o principal entrypoint de contexto.
Praticamente todo fluxo protegido depende de:

- usuário autenticado
- role válida
- `company_id` consistente

### Autorização

As permissões são centralizadas em [`app/models/ability.rb`](app/models/ability.rb).

Esse arquivo concentra a matriz RBAC/ABAC da aplicação. Os principais vetores de
decisão são:

- role do usuário (`admin`, `gestor`, `tecnico`)
- escopo por empresa
- ownership da entidade
- relacionamento indireto, por exemplo técnico vendo apenas OS atribuídas

Padrão esperado:

- regras globais por role ficam em métodos dedicados
- controllers usam `authorize!` ou `load_and_authorize_resource`
- views escondem ações não autorizadas, mas a regra real precisa estar no backend

## Domínios funcionais principais

### 1. Empresa e assinatura

`Company` é o agregado raiz de tenancy. Ela centraliza:

- usuários
- clientes
- ordens de serviço
- tickets
- assinatura corrente

`Subscription` modela o estado comercial do cliente SaaS. Alguns comportamentos
de produto dependem diretamente do plano corrente, como:

- limite de técnicos
- limite de ordens de serviço
- nível de suporte

### 2. Usuários e papéis

`User` suporta papéis distintos no mesmo sistema:

- `gestor`: opera a empresa
- `tecnico`: executa ordens de serviço
- `admin`: opera a plataforma

O sistema também usa semântica como `can_be_technician`, o que exige cuidado na
leitura das regras de negócio e nos filtros de consulta.

### 3. Clientes

`Client` representa o cliente final da empresa operadora. O relacionamento com
`OrderService` é central para o fluxo operacional.

### 4. Ordens de serviço

`OrderService` é um dos aggregates centrais do sistema. Ela concentra:

- cliente
- empresa
- técnicos vinculados via `Assignment`
- itens de serviço
- anexos
- transições de status
- disparos de notificação por email

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
- notificações
- regras de edição
- visibilidade de ações
- cálculos operacionais e financeiros

### 5. Atribuição de técnicos

`Assignment` faz o binding entre `User` técnico e `OrderService`.

Esse model encapsula validações importantes:

- usuário atribuído deve ser técnico
- não pode haver sobreposição indevida de janela operacional
- não se deve atribuir técnico em status não permitidos

Também é um ponto de fan-out de notificação para técnicos.

### 6. Itens de serviço

`ServiceItem` compõe o valor operacional de cada OS. Sempre que houver cálculo
de valor agregado, o baseline correto é:

`quantity * unit_price`

Evite somar apenas `unit_price`, pois isso subestima o total quando a
quantidade for maior que 1.

### 7. Suporte e base de conhecimento

`SupportTicket` e `SupportMessage` cobrem o fluxo de suporte conversacional.

`KnowledgeBaseArticle` cobre artigos de ajuda e agora suporta segregação por
audiência via campo `audience`, tipicamente:

- `gestor`
- `tecnico`

## Dashboards por role

### Dashboard de gestor

Foco em indicadores de operação da empresa:

- clientes
- técnicos
- volume de OS
- faturamento bruto operacional
- ordens recentes
- distribuição por status

O "faturamento bruto" no dashboard de gestor é um indicador operacional,
derivado da soma dos itens de serviço, não um fluxo de caixa contábil.

### Dashboard de técnico

Foco em execução:

- agenda do dia
- OS em andamento
- OS atrasadas
- concluídas no mês
- próximas visitas
- atribuições correntes
- pendentes de finalização

Esse dashboard usa um recorte de `OrderService` filtrado pelas OS atribuídas ao
`current_user`.

### Dashboard de admin

Foco em saúde da plataforma:

- empresas ativas
- assinaturas ativas
- MRR estimado
- tickets abertos
- novas empresas no mês
- usuários no mês
- OS finalizadas no mês
- assinaturas em atenção

Boa prática adotada recentemente:

- mover `where` e agregações repetidas para scopes/métodos nos models
- manter controller fino e sem query ad hoc demais

## Regras específicas para técnico

O papel `tecnico` possui um conjunto de restrições operacionais relevantes:

- pode ver apenas OS associadas a ele
- não acessa tickets de suporte
- acessa a base de conhecimento via submenu de suporte
- tem dashboard dedicado
- pode editar apenas subconjunto controlado da OS

Na tela de edição de OS:

- campos estruturais ficam visíveis, mas `disabled`
- o backend aceita apenas os atributos autorizados
- `attachments` e `observations` são o foco principal de update

Em OS atrasada:

- apenas `gestor` pode reagendar
- técnico não deve conseguir burlar isso via URL direta

## Área financeira

A área `Financeira` foi modelada como um módulo operacional para gestor,
baseado no valor dos itens de serviço por status da OS.

Semântica atual:

- `Faturamento Realizado`: OS `finalizada`
- `Faturamento Pendente`: OS `pendente`, `agendada`, `em_andamento`,
  `concluida`, `atrasada`
- `cancelada` fica fora do cálculo

Isso não é fluxo de caixa contábil. É uma leitura operacional de backlog e
receita consolidada sobre o agregado `OrderService`.

## Background jobs e assincronia

O projeto usa Sidekiq para execução assíncrona, principalmente em:

- envio de emails
- eventos de notificação
- processamento de pagamentos de cadastro
- relatórios/exportações
- ciclo de vida e reconciliação de assinaturas
- limpeza de auditoria

Cron jobs carregados no startup do Sidekiq:

| Job | Cron | Objetivo |
| --- | --- | --- |
| `MarkOverdueOrderServicesJob` | `* * * * *` | marca OS como atrasadas quando o horário agendado já passou |
| `Subscriptions::CycleSubscriptionsJob` | `0 10 * * *` | cicla assinaturas aptas para renovação |
| `Subscriptions::NotifyOverdueSubscriptionsJob` | `0 9 * * *` | notifica assinaturas vencidas há 5 dias |
| `Subscriptions::ExpireOverdueSubscriptionsJob` | `0 11 * * *` | expira assinaturas vencidas há 10 dias ou mais |
| `Subscriptions::FinalizeScheduledCancellationsJob` | `15 11 * * *` | finaliza cancelamentos agendados para o fim do período |
| `Subscriptions::ReconcileSubscriptionsJob` | `0 12 * * *` | reconcilia status local de assinaturas com o Mercado Pago |
| `Subscriptions::ReprocessPendingPaymentsJob` | `30 12 * * *` | reprocessa assinaturas `pending` de pix/boleto sem webhook processado |
| `Audit::CleanupEventsJob` | `0 2 * * *` | remove `audit_events` antigos conforme política de retenção |

Os agendamentos ficam em `config/initializers/sidekiq_schedules.rb`, usam fila
`default` e timezone `America/Sao_Paulo`.

### Variáveis de ambiente de reconciliação

Os jobs de assinaturas usam janelas de tempo para reduzir custo de chamadas ao
gateway e limitar o volume processado por execução.

- `SUBSCRIPTIONS_RECONCILIATION_WINDOW_DAYS`
  Controla a janela (em dias) do
  `Subscriptions::ReconcileSubscriptionsJob`.
  Valor padrão: `30`.
- `SUBSCRIPTIONS_PENDING_REPROCESS_WINDOW_DAYS`
  Controla a janela (em dias) do
  `Subscriptions::ReprocessPendingPaymentsJob`.
  Valor padrão: `30`.

Se as variáveis estiverem ausentes, vazias, `0` ou negativas, os jobs usam
fallback para `30` dias.

### Variáveis de ambiente de retenção de auditoria

O job `Audit::CleanupEventsJob` aplica a política de retenção em `audit_events`
no modo hot-only, removendo registros antigos em lotes.

- `AUDIT_LOG_RETENTION_DAYS`
  Janela de retenção em dias para `audit_events`.
  Valor padrão: `180`.
- `AUDIT_LOG_CLEANUP_BATCH_SIZE`
  Quantidade de registros por lote durante a limpeza.
  Valor padrão: `1000`.
- `AUDIT_LOG_CLEANUP_DRY_RUN`
  Quando `true`, não remove dados; apenas mede quantos seriam removidos.
  Valor padrão: `false`.

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

Catálogo inicial de ações:

- autenticação: `auth.*`
- usuários/técnicos: `user.*` e `technician.*`
- clientes: `client.*`
- ordens de serviço: `order_service.*`
- cupons: `coupon.*`
- assinaturas/pagamentos: `subscription.*`
- webhooks: `webhook.*`
- sistema/jobs: `job.*` e `system.*`

Padrão de nome:

- `<domínio>.<evento>[.<subevento>]`
- exemplos: `order_service.status.changed`, `webhook.signature.invalid`

As ações válidas ficam centralizadas em:

- `Audit::ActionCatalog::ALL`
- arquivo: [`app/services/audit/action_catalog.rb`](app/services/audit/action_catalog.rb)

Toda vez que aparecer `deliver_later`, o fluxo real passa por:

1. serialização do job
2. persistência/lógica da fila no Redis
3. consumo pelo processo `sidekiq`
4. reidratação de argumentos, inclusive `GlobalID`
5. execução do mailer

Isso significa que erros em mailers podem aparecer tardiamente, fora da
request original.

## Action Mailer e notificações de OS

`OrderService` possui callbacks que disparam emails transacionais em eventos de
mudança de estado.

Exemplos:

- criação
- agendamento
- início de atendimento
- conclusão
- finalização
- atraso

Quando o log mostra `Performing ActionMailer::MailDeliveryJob`, isso significa
que o worker retirou o job da fila e iniciou a renderização. Só há garantia real
de sucesso quando o job conclui sem `WARN` ou `ERROR` subsequente para o mesmo
job.

## Seeds e bootstrap de dados

O bootstrap usa carga ordenada por ambiente:

- `db/seeds/common`
- `db/seeds/development`
- `db/seeds/production`

O seed de preparação limpa a base antes de repopular. Como existem várias FKs,
foi necessário usar `disable_referential_integrity` para evitar violações
durante `delete_all`.

Pontos relevantes do dataset de desenvolvimento:

- empresas
- usuários
- clientes
- ordens de serviço
- atribuições
- itens de serviço
- artigos de base de conhecimento
- tickets e mensagens de suporte

## Base de conhecimento

Os artigos markdown em `docs/gestor` e `docs/tecnico` servem como fonte para a
base de conhecimento exibida no app.

Implicações técnicas:

- a estrutura de pastas vira categoria semântica
- o `seed` transforma markdown em HTML
- o campo `audience` segmenta artigos por papel

Isso cria um fluxo híbrido:

- markdown versionado em repositório
- conteúdo indexado em banco
- renderização filtrada por role no app

## Backup de banco (produção)

Backup automático diário via script de host:

- script: [`bin/backup_db`](bin/backup_db)
- formato: `pg_dump` custom (`.dump`)
- retenção padrão: `7` dias (`BACKUP_RETENTION_DAYS`)

Exemplo de cron (todo dia às 02:15):

```bash
15 2 * * * cd /opt/catalyst_ops && BACKUP_RETENTION_DAYS=7 /opt/catalyst_ops/bin/backup_db >> /var/log/catalyst_ops_backup.log 2>&1
```

Diretório padrão dos arquivos:

- `/opt/catalyst_ops/backups/postgres`

## Restore de banco (produção/homologação)

Script de restore:

- [`bin/restore_db`](bin/restore_db)

Pré-condições:

- Fazer restore preferencialmente em homologação para validação.
- Em produção, parar `web` e `sidekiq` antes do restore para evitar concorrência.
- Ter um arquivo `.dump` válido gerado pelo `bin/backup_db`.

Restore básico:

```bash
cd /opt/catalyst_ops
CONFIRM_RESTORE=yes ./bin/restore_db /opt/catalyst_ops/backups/postgres/catalyst_ops_production_YYYYMMDD_HHMMSS.dump
```

Restore para banco alvo específico:

```bash
cd /opt/catalyst_ops
TARGET_DB=catalyst_ops_homolog CONFIRM_RESTORE=yes ./bin/restore_db /opt/catalyst_ops/backups/postgres/catalyst_ops_production_YYYYMMDD_HHMMSS.dump
```

Sequência recomendada em produção:

```bash
cd /opt/catalyst_ops
docker compose stop web sidekiq
CONFIRM_RESTORE=yes ./bin/restore_db /opt/catalyst_ops/backups/postgres/SEU_ARQUIVO.dump
docker compose up -d web sidekiq
```

Validação pós-restore:

- Rodar `docker compose exec web bundle exec rails db:migrate:status`.
- Acessar login/app/admin e validar fluxo básico de autenticação.
- Conferir `docker compose logs --tail=200 web sidekiq db`.

## Convenções recomendadas

### Querying

- prefira scopes expressivos no model
- evite `where` repetitivo em controllers
- preserve scoping por empresa
- cuidado com `joins + distinct + order` no PostgreSQL

### Autorização

- regra de permissão sempre no backend
- view apenas reflete o estado autorizado
- paths sensíveis devem ser protegidos contra acesso direto

### Cálculo de valores

- para total de itens, use `quantity * unit_price`
- para leitura financeira, explicite se o valor é previsto ou realizado
- não chame de fluxo de caixa algo que não modele entrada e saída real

### Seeds

- mantenha ordenação lexical previsível
- se um seed depender de outro, o nome do arquivo precisa refletir isso
- ex.: `9-support_tickets.rb` antes de `9a-support_messages.rb`

## CI/CD e governança de merge

### Pipeline de deploy

O deploy automatizado roda via GitHub Actions em
[` .github/workflows/deploy.yml `](.github/workflows/deploy.yml),
executando [`bin/deploy`](bin/deploy) no servidor.

Detalhe operacional importante:

- o workflow executa `bash /opt/catalyst_ops/bin/deploy` (sem `chmod`)
- isso evita alterar permissão do arquivo no servidor e sujar `git status`

Fluxo técnico relevante:

- `git fetch` + diff de arquivos alterados para calcular plano de deploy
- rebuild de imagem quando houver mudanças sensíveis (ex.: `db/migrate/*`,
  `app/*`, `config/*`, `lib/*`, dependências e dockerfiles)
- restart de `web`/`sidekiq` quando necessário
- `db:migrate` executado via `docker compose run --rm web ...` para aplicar
  pendências

Importante para troubleshooting:

- produção não usa bind mount de código no `web`; o código em runtime vem da
  imagem Docker
- sem rebuild, migration nova pode existir no host git mas não no container
- se isso ocorrer, o `db:migrate` não enxerga o arquivo da migration

### Política de janela para PRs

A política de janela está em
[` .github/workflows/policy-window.yml `](.github/workflows/policy-window.yml).

Regras implementadas:

- título do PR não pode começar com marcador de IA, como `[codex]`, `[IA]`,
  `Claude:`, `Copilot -`, etc.
- mudanças sensíveis: somente `22:00-06:00` (America/Sao_Paulo)
- mudanças simples: somente `09:00-18:00` (America/Sao_Paulo)
- PR com migration deve conter apenas `db/migrate/*` e opcionalmente
  `db/schema.rb`

Observação:

- o workflow bloqueia merge via check; para aplicação real, Branch Protection da
  `main` deve exigir o status check `PR Window Policy / merge_window_policy`
- como o check é avaliado no momento da execução do job, para política de hora
  estrita no instante do merge recomenda-se habilitar `Require branches to be
  up to date before merging` na `main` ou usar merge queue (`merge_group`) para
  revalidação no fluxo final de merge

## Pontos de atenção

### Scope global enganoso

Qualquer scope com `limit(1)` em model compartilhado deve ser revisado com
cuidado. Em especial quando a intenção de negócio for "um registro por empresa"
e não "um registro global".

### Integridade de assinatura

Se a regra de negócio for "uma única assinatura ativa por empresa", isso deve
ser sustentado não apenas pela aplicação, mas idealmente por restrição de banco
ou pelo menos por validação consistente.

### SQL ambíguo

Em relações com `includes`, `joins` e ordenação por colunas comuns como
`updated_at`, qualifique explicitamente a tabela:

- `order_services.updated_at`
- `order_services.finished_at`
- `order_services.started_at`

### Distinct com order no PostgreSQL

`SELECT DISTINCT` combinado com `ORDER BY` em expressões não selecionadas pode
quebrar. Se isso aparecer, revise:

- necessidade real de `distinct`
- expressão usada no `order`
- possibilidade de qualificar e simplificar a query

## Referências rápidas

- [`README.md`](README.md)
- [`AGENTS.md`](AGENTS.md)
- [`docs/dev/ai/00_indice.md`](docs/dev/ai/00_indice.md)
- [`app/models/ability.rb`](app/models/ability.rb)
- [`app/models/order_service.rb`](app/models/order_service.rb)
- [`app/models/company.rb`](app/models/company.rb)
- [`app/models/subscription.rb`](app/models/subscription.rb)
- [`app/controllers/app/dashboard_controller.rb`](app/controllers/app/dashboard_controller.rb)
- [`app/controllers/admin/dashboard_controller.rb`](app/controllers/admin/dashboard_controller.rb)
- [`app/controllers/app/support_controller.rb`](app/controllers/app/support_controller.rb)
- [`app/mailers/order_service_mailer.rb`](app/mailers/order_service_mailer.rb)
- [`docs/gestor`](docs/gestor)
- [`docs/tecnico`](docs/tecnico)

## Nota final para manutenção

Se você for mexer em fluxos sensíveis deste projeto, revise sempre estes eixos:

- tenant isolation por `company_id`
- matrix de permissão em `Ability`
- lifecycle de `OrderService`
- side effects assíncronos no Sidekiq
- consistência entre controller, model, view e mailer
