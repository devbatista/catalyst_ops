# CatalystOps — Ambiente Docker

CatalystOps é uma plataforma **SaaS para gestão de operações e serviços técnicos**,
desenvolvida em Ruby on Rails e executada **100% em Docker**, tanto em desenvolvimento
quanto em produção.

Este README é **Docker‑first**: você não precisa instalar Ruby, Rails ou PostgreSQL
localmente para rodar o projeto.

---

## Visão geral

O CatalystOps permite que empresas prestadoras de serviços técnicos organizem:

- Clientes
- Ordens de Serviço (OS)
- Técnicos e atribuições
- Agenda de atendimentos
- Anexos (fotos, documentos)
- Relatórios operacionais

A arquitetura foi pensada para:

- Padronização de ambiente
- Facilidade de onboarding de desenvolvedores
- Escalabilidade como SaaS

---

## Requisitos

- Docker
- Docker Compose (pode usar `docker compose` ou `docker-compose`)

Versões recentes são recomendadas.

---

## Arquitetura Docker

Os containers são orquestrados via `docker-compose.yml` (com
`docker-compose.override.yml` para desenvolvimento).

### Serviços principais

| Serviço | Container     | Descrição                                |
|--------|---------------|------------------------------------------|
| web    | `catalystops-app` | Aplicação Ruby on Rails                 |
| db     | `postgres:15` | Banco de dados PostgreSQL               |
| redis  | `redis:7`     | Cache e background jobs (Sidekiq)       |
| sidekiq| `catalystops-app` | Processamento de jobs em background     |
| nginx  | `nginx:latest`| Proxy reverso / subdomínios locais      |

Fluxo simplificado:

`cliente → nginx → web (Rails) → PostgreSQL`  
`                               └→ Redis (Sidekiq / cache)`

### Montagem de código (dev)

No desenvolvimento, o arquivo `docker-compose.override.yml` monta o código
local dentro do container:

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

Isso significa que **qualquer alteração no código é refletida imediatamente**
dentro do container (não precisa rebuild da imagem; às vezes só restart se
mexer em gems).

---

## Variáveis de ambiente (`.env`)

As variáveis ficam no arquivo `.env` (não versionado).  
Um exemplo completo está em `.env_example`.

### Criar o arquivo

```bash
cp .env_example .env
```

### Principais variáveis

```env
# Ambiente
RAILS_ENV=development              # development para local, production para servidor
WEB_PORT=3000                      # porta externa do Rails (nginx também usa)

# Banco de dados (PostgreSQL)
POSTGRES_DB=catalyst_ops_development
POSTGRES_USER=user_database
POSTGRES_PASSWORD=pass_database
POSTGRES_PORT=5432                 # porta exposta no host

# Redis
REDIS_PORT=6379

# Rails secrets / chaves
RAILS_LOG_TO_STDOUT=true
RAILS_MASTER_KEY='your_rails_master_key_here'
SECRET_KEY_BASE='your_secret_key_base_here'

# Assets (build de imagem, principalmente para produção)
PRECOMPILE_ASSETS=0                # 0 para dev (não precompila), 1 para prod
ASSETS_SECRET_KEY_BASE='your_assets_secret_key_base_here'

# Integração Mercado Pago
MP_TEST_ACCESS_TOKEN='TEST_ACCESS_TOKEN_EXAMPLE'
MP_PRODUCTION_ACCESS_TOKEN='APP_USR_PRODUCTION_ACCESS_TOKEN_EXAMPLE'
MP_PUBLIC_KEY='APP_USR_PUBLIC_KEY_EXAMPLE'
MP_PUBLIC_KEY_TEST='TEST_PUBLIC_KEY_EXAMPLE'
MP_WEBHOOK_SECRET='WEBHOOK_SECRET_EXAMPLE'
```

> Em desenvolvimento, deixe `RAILS_ENV=development` e `PRECOMPILE_ASSETS=0`.

---

## Subdomínios locais (`/etc/hosts`)

O projeto utiliza vários subdomínios para separar áreas da aplicação:

- `catalystops.local`      → domínio “raiz”
- `app.catalystops.local`  → painel principal (aplicação)
- `login.catalystops.local`→ tela de login
- `admin.catalystops.local`→ área administrativa
- `register.catalystops.local` → onboarding / cadastro
- `sidekiq.catalystops.local`  → painel do Sidekiq

### 1. Editar `/etc/hosts` (macOS / Linux)

Abra o arquivo com privilégios de administrador:

```bash
sudo nano /etc/hosts
```

Adicione as linhas:

```text
127.0.0.1   catalystops.local
127.0.0.1   app.catalystops.local
127.0.0.1   login.catalystops.local
127.0.0.1   admin.catalystops.local
127.0.0.1   register.catalystops.local
127.0.0.1   sidekiq.catalystops.local
```

Salve e feche.

### 2. Acessando a aplicação

Depois de subir os containers (ver seção abaixo), você poderá acessar:

- `http://app.catalystops.local`
- `http://login.catalystops.local`
- `http://admin.catalystops.local`
- `http://register.catalystops.local`
- `http://sidekiq.catalystops.local` (quando configurado no nginx)

O serviço `nginx` (porta 80 e 443) faz o roteamento para o container `web`.

---

## Setup inicial (primeira execução)

### 1. Build e subida dos containers

Na raiz do projeto:

```bash
docker compose up -d --build
# ou, se sua instalação usar o binário antigo:
# docker-compose up -d --build
```

Isso irá:

- Buildar a imagem `catalystops-app` usando o `Dockerfile`
- Subir `db`, `redis`, `web`, `sidekiq` e `nginx`

### 2. Criar banco e rodar migrations

```bash
docker compose exec web bin/rails db:create db:migrate
# ou: docker-compose exec web bin/rails db:create db:migrate
```

### 3. (Opcional) Popular dados iniciais

```bash
docker compose exec web bin/rails db:seed
```

### 4. Acessar a aplicação

Com `/etc/hosts` configurado:

- `http://app.catalystops.local` (via nginx)  
ou, diretamente no container `web`:

- `http://localhost:3000` (usa `WEB_PORT` do `.env`)

---

## Comandos úteis

### Logs

```bash
docker compose logs -f web
docker compose logs -f sidekiq
```

### Console Rails

```bash
docker compose exec web bin/rails console
```

### Migrations

```bash
docker compose exec web bin/rails db:migrate
```

### Testes

```bash
docker compose exec web bin/rails test
```

### Reiniciar serviços

```bash
docker compose restart web
docker compose restart sidekiq
```

### Parar todos os containers

```bash
docker compose down
```

### Reset completo (⚠️ apaga banco e volumes)

```bash
docker compose down -v
docker compose up -d --build
```

---

## Sobre atualização de código (dev)

Como o `docker-compose.override.yml` monta seu diretório de trabalho dentro
do container (`.:/rails`):

- Alterações em arquivos Ruby, views, JS, CSS etc. entram **na hora**.
- Geralmente não é preciso rebuild da imagem, só recarregar a página.
- Se você adicionar/atualizar gems, rode:

```bash
docker compose exec web bundle install
docker compose restart web
docker compose restart sidekiq
```

---

## Background jobs (Sidekiq) e Redis

O Redis é usado para:

- Fila de jobs (Sidekiq)
- Cache (quando habilitado)

Certifique‑se de que:

- `redis` esteja rodando;
- `sidekiq` esteja em execução (`docker compose ps`).

O painel do Sidekiq pode ser exposto em `sidekiq.catalystops.local`
quando configurado nas rotas e no nginx.

---

## Produção (visão geral)

Para produção (servidor Linux):

1. Copiar o projeto para o servidor
2. Criar `.env` com `RAILS_ENV=production` e `PRECOMPILE_ASSETS=1`
3. Subir containers com `docker compose up -d --build`
4. Rodar `db:create db:migrate`
5. Configurar DNS real + nginx/SSL (mapeando para os containers)

---

## Observação final

Se algo não funcionar conforme esperado:

1. Verifique o `.env`
2. Confira `docker compose ps` e `docker compose logs`
3. Revise `docker-compose.yml` e `docker-compose.override.yml`

Para dúvidas específicas, abra uma issue interna ou consulte a documentação
em `docs/`.