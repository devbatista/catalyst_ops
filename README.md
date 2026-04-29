# CatalystOps

CatalystOps é uma plataforma SaaS para gestão de operações e serviços técnicos,
desenvolvida em Ruby on Rails e preparada para rodar em Docker tanto em
desenvolvimento quanto em produção.

Este projeto foi estruturado para que o ambiente local seja o mais próximo
possível do ambiente real de execução. A ideia do repositório é simples:

- Rails para a aplicação web
- PostgreSQL para persistência
- Redis para fila e cache
- Sidekiq para jobs em background
- Nginx para roteamento por subdomínio

## Objetivo do sistema

O CatalystOps permite que empresas prestadoras de serviços técnicos organizem:

- clientes
- ordens de serviço
- técnicos e atribuições
- agenda de atendimento
- anexos
- suporte interno
- base de conhecimento
- assinaturas e operação SaaS

## Stack principal

| Componente | Função |
| --- | --- |
| Ruby on Rails | aplicação principal |
| PostgreSQL 15 | banco de dados |
| Redis 7 | fila e cache |
| Sidekiq | processamento assíncrono |
| Nginx | proxy reverso / subdomínios |
| Docker Compose | orquestração local |

## Estrutura geral do ambiente

Os serviços são definidos em [`docker-compose.yml`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docker-compose.yml) e, em desenvolvimento, complementados por [`docker-compose.override.yml`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docker-compose.override.yml).

Serviços principais:

| Serviço | Container | Papel no ambiente |
| --- | --- | --- |
| `web` | `catalystops-app` | executa o Rails |
| `sidekiq` | `catalystops-app` | processa jobs em background |
| `db` | `postgres:15` | banco de dados |
| `redis` | `redis:7` | fila do Sidekiq e cache |
| `nginx` | `nginx:latest` | entrada HTTP/HTTPS e subdomínios |

Fluxo simplificado:

`cliente -> nginx -> web (Rails) -> PostgreSQL`

`cliente -> nginx -> web (Rails) -> Redis -> Sidekiq`

## Requisitos

Para rodar o projeto localmente, você precisa ter:

- Docker
- Docker Compose
- acesso ao arquivo `config/master.key` ou ao valor de `RAILS_MASTER_KEY`

Você não precisa instalar Ruby, Rails, PostgreSQL nem Redis diretamente na sua máquina se for usar o fluxo padrão com Docker.

## Variáveis de ambiente

As configurações ficam em `.env`. Um exemplo base existe em [` .env_example `](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/.env_example).

Crie o arquivo local com:

```bash
cp .env_example .env
```

Principais variáveis:

```env
MP_TEST_ACCESS_TOKEN='TEST_ACCESS_TOKEN_EXAMPLE'
MP_PRODUCTION_ACCESS_TOKEN='APP_USR_PRODUCTION_ACCESS_TOKEN_EXAMPLE'
MP_PUBLIC_KEY='APP_USR_PUBLIC_KEY_EXAMPLE'
MP_PUBLIC_KEY_TEST='TEST_PUBLIC_KEY_EXAMPLE'
MP_WEBHOOK_SECRET='WEBHOOK_SECRET_EXAMPLE'

RAILS_ENV=development
POSTGRES_DB=catalyst_ops_development
POSTGRES_USER=user_database
POSTGRES_PASSWORD=password_database
POSTGRES_PORT=5432

REDIS_PORT=6379
WEB_PORT=3000

RAILS_LOG_TO_STDOUT=true
RAILS_MASTER_KEY='your_rails_master_key_here'
SECRET_KEY_BASE='your_secret_key_base_here'

PRECOMPILE_ASSETS=0
ASSETS_SECRET_KEY_BASE='your_assets_secret_key_base_here'
```

Observações:

- em desenvolvimento, use `RAILS_ENV=development`
- para desenvolvimento, `PRECOMPILE_ASSETS=0` costuma ser suficiente
- `RAILS_MASTER_KEY` precisa bater com as credenciais do projeto
- `SECRET_KEY_BASE` pode ser gerada com `bin/rails secret`

## Subdomínios locais

O projeto utiliza subdomínios para separar áreas da aplicação:

- `catalystops.local`
- `app.catalystops.local`
- `login.catalystops.local`
- `admin.catalystops.local`
- `register.catalystops.local`
- `webhook.catalystops.local`
- `sidekiq.catalystops.local`

### Ajuste do `/etc/hosts`

No macOS ou Linux:

```bash
sudo nano /etc/hosts
```

Adicione:

```text
127.0.0.1 catalystops.local
127.0.0.1 app.catalystops.local
127.0.0.1 login.catalystops.local
127.0.0.1 admin.catalystops.local
127.0.0.1 register.catalystops.local
127.0.0.1 webhook.catalystops.local
127.0.0.1 sidekiq.catalystops.local
```

### Endereços mais usados

Depois de subir o ambiente:

- `https://app.catalystops.local`
- `https://login.catalystops.local`
- `https://admin.catalystops.local`
- `https://register.catalystops.local`
- `https://webhook.catalystops.local`
- `https://sidekiq.catalystops.local`

Opcionalmente, você também pode acessar o Rails diretamente por:

- `http://localhost:3000`

## Como subir o projeto

### 1. Build e subida dos containers

Na raiz do projeto:

```bash
docker compose up -d --build
```

Isso sobe:

- `db`
- `redis`
- `web`
- `sidekiq`
- `nginx`

### 2. Criar banco e rodar migrations

```bash
docker compose exec web bin/rails db:create db:migrate
```

### 3. Popular dados iniciais

```bash
docker compose exec web bin/rails db:seed
```

### 4. Validar o ambiente

```bash
docker compose ps
docker compose logs -f web
docker compose logs -f sidekiq
```

## Montagem de código no desenvolvimento

O arquivo [`docker-compose.override.yml`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docker-compose.override.yml) monta o diretório do projeto dentro dos containers `web` e `sidekiq`:

```yaml
services:
  web:
    volumes:
      - .:/rails
      - ./storage:/rails/storage

  sidekiq:
    volumes:
      - .:/rails
      - ./storage:/rails/storage
```

Na prática, isso significa:

- alterações em Ruby, views, JS e CSS refletem imediatamente no container
- em geral, não é necessário rebuild quando a mudança é apenas de código
- se você alterar gems, é recomendável rodar `bundle install` no container e reiniciar `web` e `sidekiq`

Exemplo:

```bash
docker compose exec web bundle install
docker compose restart web
docker compose restart sidekiq
```

## Comandos úteis

### Logs

```bash
docker compose logs -f web
docker compose logs -f sidekiq
docker compose logs -f nginx
docker compose logs -f db
```

### Console Rails

```bash
docker compose exec web bin/rails console
```

### Executar um runner

```bash
docker compose exec web bin/rails runner "puts Company.count"
```

### Migrations

```bash
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:rollback
```

### Testes

```bash
docker compose exec web bin/rails test
```

### Reiniciar serviços

```bash
docker compose restart web
docker compose restart sidekiq
docker compose restart nginx
```

### Derrubar ambiente

```bash
docker compose down
```

### Reset completo do ambiente

Use com cuidado. Isso apaga volumes e banco local:

```bash
docker compose down -v
docker compose up -d --build
```

## Como funcionam os seeds

O arquivo [`db/seeds.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds.rb) carrega seeds em duas etapas:

1. tudo que estiver em `db/seeds/common`
2. tudo que estiver em `db/seeds/<ambiente>`

No ambiente `development`, a ordem atual é:

- [`db/seeds/common/0-prepare.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/common/0-prepare.rb)
- [`db/seeds/common/1.plans.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/common/1.plans.rb)
- [`db/seeds/development/2-companies.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/development/2-companies.rb)
- [`db/seeds/development/3-users.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/development/3-users.rb)
- [`db/seeds/development/4-clients.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/development/4-clients.rb)
- [`db/seeds/development/5-order_services.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/development/5-order_services.rb)
- [`db/seeds/development/6-assignments.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/development/6-assignments.rb)
- [`db/seeds/development/7-service_items.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/development/7-service_items.rb)
- [`db/seeds/development/8-knowledge_base_articles.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/development/8-knowledge_base_articles.rb)
- [`db/seeds/development/9-support_tickets.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/development/9-support_tickets.rb)
- [`db/seeds/development/9a-support_messages.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/development/9a-support_messages.rb)

### Preparação da base

O seed [`db/seeds/common/0-prepare.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/common/0-prepare.rb) limpa os dados antigos antes de recriar os registros. Essa limpeza usa `disable_referential_integrity` para evitar erro de chave estrangeira durante `delete_all`.

Se o `db:seed` falhar, confira primeiro:

- se o banco está acessível
- se as migrations estão atualizadas
- se o comando está rodando dentro do container correto

## Background jobs com Sidekiq e Redis

Redis é usado para:

- fila do Sidekiq
- cache, quando habilitado

Para jobs funcionarem corretamente:

- `redis` precisa estar em execução
- `sidekiq` precisa estar em execução
- o `REDIS_URL` precisa apontar para o container `redis`

Cheque rapidamente:

```bash
docker compose ps
docker compose logs -f sidekiq
```

### Cron jobs carregados no startup do Sidekiq

Os agendamentos recorrentes são registrados no startup do Sidekiq via
[`config/initializers/sidekiq_schedules.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/config/initializers/sidekiq_schedules.rb),
usando `Sidekiq::Cron::Job.load_from_hash!`.

Timezone configurado para os agendamentos:

- `America/Sao_Paulo`

Cron jobs atuais:

| Job | Cron | Frequência | Objetivo |
| --- | --- | --- | --- |
| `MarkOverdueOrderServicesJob` | `* * * * *` | a cada minuto | marca OS como atrasadas quando o horário agendado já passou |
| `Subscriptions::CycleSubscriptionsJob` | `0 10 * * *` | diariamente às 10:00 | cicla assinaturas aptas para renovação |
| `Subscriptions::NotifyOverdueSubscriptionsJob` | `0 9 * * *` | diariamente às 09:00 | notifica assinaturas vencidas há 5 dias |
| `Subscriptions::ExpireOverdueSubscriptionsJob` | `0 11 * * *` | diariamente às 11:00 | expira assinaturas vencidas há 10 dias ou mais |
| `Subscriptions::ReconcileSubscriptionsJob` | `0 12 * * *` | diariamente às 12:00 | reconcilia status local de assinaturas com o Mercado Pago |

Observações:

- esses cron jobs só ficam ativos com o processo `sidekiq` em execução
- a fila usada nesses agendamentos é `default`
- a concorrência base do Sidekiq está em [`config/sidekiq.yml`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/config/sidekiq.yml)
- para validar se os agendamentos foram carregados, acompanhe os logs do container `sidekiq`

### Janela de reconciliação de assinaturas

Os jobs de reconciliação/reprocessamento usam janela para reduzir chamadas ao
gateway:

- `Subscriptions::ReconcileSubscriptionsJob`
  usa `subscriptions.updated_at` e env:
  `SUBSCRIPTIONS_RECONCILIATION_WINDOW_DAYS`
- `Subscriptions::ReprocessPendingPaymentsJob`
  usa query operacional de pendentes sem webhook processado e env:
  `SUBSCRIPTIONS_PENDING_REPROCESS_WINDOW_DAYS`

Padrão para ambas:

- últimos `30` dias
- se valor ausente/inválido (`0` ou negativo), fallback automático para `30`

Exemplo:

```env
SUBSCRIPTIONS_RECONCILIATION_WINDOW_DAYS=30
SUBSCRIPTIONS_PENDING_REPROCESS_WINDOW_DAYS=30
```

## Fluxo de emails

Os envios de email usam `deliver_later`, então passam pelo Sidekiq.

Isso vale para fluxos como:

- boas-vindas de usuário
- notificações de ordens de serviço
- sugestões enviadas pela área de suporte

### Ordem de Serviço

No model [`app/models/order_service.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/models/order_service.rb), existem callbacks que enfileiram emails em diferentes mudanças de estado:

- `after_create :notify_create`
- `after_update :notify_complete`
- `after_update :notify_scheduled`
- `after_update :notify_finished`
- `after_update :notify_in_progress`
- `after_update :notify_overdue`

Esses callbacks chamam o [`OrderServiceMailer`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/mailers/order_service_mailer.rb).

## Como interpretar logs do Sidekiq

Exemplo comum:

```text
Performing ActionMailer::MailDeliveryJob ...
Rendered order_service_mailer/notify_create.html.erb ...
Rendered layout layouts/mailer.html.erb ...
```

Isso significa:

- o job foi retirado da fila
- o mailer começou a ser executado
- a view do email foi renderizada

Isso ainda não garante entrega final. Para considerar sucesso, o log precisa fechar sem erro, normalmente com `Performed ActionMailer::MailDeliveryJob` ou sem `WARN` e `ERROR` subsequentes para o mesmo job.

Se houver atraso grande entre `enqueued_at` e `Performing`, normalmente existe backlog ou o `sidekiq` ficou parado durante algum período.

## Estrutura de documentação interna

O projeto também possui documentação funcional em [`docs/`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docs):

- [`docs/gestor`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docs/gestor)
- [`docs/tecnico`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docs/tecnico)

Esses arquivos são usados como base para artigos da base de conhecimento.

## Troubleshooting

### `db:seed` falha com chave estrangeira

Verifique se o seed de limpeza está atualizado em [`db/seeds/common/0-prepare.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds/common/0-prepare.rb) e se o comando foi rodado depois da correção.

### Sidekiq não processa emails

Confira:

- `docker compose ps`
- `docker compose logs -f sidekiq`
- `docker compose logs -f redis`

Se os jobs estiverem acumulados e depois forem processados de uma vez, isso normalmente indica indisponibilidade temporária do `sidekiq`.

### Mudança de código não refletiu

Se foi mudança de gem ou dependência:

```bash
docker compose exec web bundle install
docker compose restart web
docker compose restart sidekiq
```

Se foi mudança simples de código Ruby ou view, normalmente basta recarregar a página.

### Erro local de Ruby ou Bundler fora do Docker

Este projeto é Docker-first. Se você rodar `bin/rails` diretamente na máquina hospedeira, pode encontrar divergências de Ruby, Bundler ou plataforma do `Gemfile`.

O caminho recomendado é executar comandos Rails dentro do container `web`.

## Fluxo recomendado para desenvolvimento

1. subir containers
2. rodar `db:create db:migrate`
3. rodar `db:seed`
4. acessar `app.catalystops.local`
5. acompanhar `web` e `sidekiq` nos logs durante novos fluxos

## Produção

Para produção, o fluxo geral é:

1. preparar `.env` com valores reais
2. subir containers com build
3. executar migrations
4. validar conectividade com banco e redis
5. configurar DNS e SSL
6. monitorar logs de `web`, `nginx` e `sidekiq`

### Deploy automatizado (GitHub Actions + bin/deploy)

O deploy de produção é acionado por workflow do GitHub Actions em
[` .github/workflows/deploy.yml `](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/.github/workflows/deploy.yml),
que executa [`bin/deploy`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/bin/deploy) no servidor via SSH.

Pontos importantes do `bin/deploy`:

- roda `git fetch` e identifica arquivos alterados entre `HEAD` local e `origin/main`
- decide quando precisa rebuild/restart de `web` e `sidekiq`
- executa `docker compose run --rm web bundle exec rails db:migrate`
  para aplicar migrations pendentes
- não encerra cedo apenas por não haver commit novo; ainda valida migrations
- ao final de um deploy bem-sucedido, remove cache de build e imagens Docker
  não usadas há mais de 7 dias (`DOCKER_PRUNE_UNTIL=168h`), sem remover volumes

Observação operacional:

- em produção, o container `web` usa código da imagem Docker
- se houver alteração que exige imagem nova (ex.: `db/migrate`, `app/*`,
  `config/*`, `lib/*`), o deploy precisa rebuild para o container enxergar o
  novo código
- a limpeza pode ser desabilitada com `PRUNE_DOCKER_AFTER_DEPLOY=false` ou
  ajustada com `DOCKER_PRUNE_UNTIL=72h`, `DOCKER_PRUNE_UNTIL=336h`, etc.

### Política de PR e janela de merge

Existe workflow de política em
[` .github/workflows/policy-window.yml `](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/.github/workflows/policy-window.yml)
para PRs da `main`.

Regras atuais:

- mudança sensível (ex.: `db/migrate/*`, `app/*`, `config/*`, `lib/*`,
  `Dockerfile`, `Gemfile.lock`) só passa na janela OFF: `22:00-06:00` BRT
- mudança simples só passa na janela comercial: `09:00-18:00` BRT
- se houver migration no PR, ele deve conter apenas `db/migrate/*` e
  opcionalmente `db/schema.rb`

## Referências rápidas

- Compose principal: [`docker-compose.yml`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docker-compose.yml)
- Override de desenvolvimento: [`docker-compose.override.yml`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docker-compose.override.yml)
- Exemplo de ambiente: [`.env_example`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/.env_example)
- Runbook de deploy/rollback: [`docs/operacao/runbook_deploy_rollback_producao.md`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docs/operacao/runbook_deploy_rollback_producao.md)
- Monitoramento de erros (Sentry): [`docs/operacao/monitoramento_erros_sentry.md`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docs/operacao/monitoramento_erros_sentry.md)
- Seeds: [`db/seeds.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/db/seeds.rb)
- Mailer de OS: [`app/mailers/order_service_mailer.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/mailers/order_service_mailer.rb)
- Model de OS: [`app/models/order_service.rb`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/app/models/order_service.rb)

## Observação final

Se algo não funcionar como esperado:

1. revise o `.env`
2. confira se os containers estão saudáveis
3. valide migrations e seeds
4. acompanhe logs de `web` e `sidekiq`
5. consulte a documentação em [`docs/`](/Users/devbatista/Programacao/devbatista/ruby/catalyst_ops/docs)
