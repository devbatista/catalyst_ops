# CatalystOps — Ambiente Docker

CatalystOps é uma plataforma **SaaS para gestão de operações e serviços técnicos**,
desenvolvida em Ruby on Rails e executada **100% em Docker**, tanto em desenvolvimento
quanto em produção.

Este README é **Docker-first**: você não precisa instalar Ruby, Rails ou PostgreSQL
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
- Docker Compose

Versões recentes são recomendadas.

---

## Arquitetura Docker

O sistema roda em containers isolados, orquestrados via Docker Compose.

### Containers principais

| Serviço | Descrição |
|------|----------|
| web | Aplicação Ruby on Rails |
| db | Banco de dados PostgreSQL |
| redis | Cache e background jobs |
| nginx | Proxy reverso (opcional / produção) |

Fluxo simplificado:

Cliente → Nginx → Web (Rails) → PostgreSQL  
                     └── Redis

---

## Estrutura do projeto (resumo)

```
.
├── docker-compose.yml
├── Dockerfile
├── .env.example
├── app/
├── config/
├── db/
├── docs_usuario_final/
├── docs_tecnico/
└── README.md
```

---

## Variáveis de ambiente

As variáveis de ambiente ficam no arquivo `.env`.

### Criando o arquivo

```bash
cp .env.example .env
```

### Exemplo de variáveis

```env
RAILS_ENV=development
DATABASE_URL=postgres://postgres:postgres@db:5432/catalystops
REDIS_URL=redis://redis:6379/0
SECRET_KEY_BASE=change_me
```

> ⚠️ Nunca versionar o arquivo `.env`.

---

## Setup inicial (primeira execução)

### 1. Subir os containers

```bash
docker-compose up -d
```

### 2. Criar banco e rodar migrations

```bash
docker-compose exec web bin/rails db:create db:migrate
```

### 3. (Opcional) Popular dados iniciais

```bash
docker-compose exec web bin/rails db:seed
```

### 4. Acessar a aplicação

```
http://localhost:3000
```

---

## Comandos úteis

### Ver logs da aplicação

```bash
docker-compose logs -f web
```

### Acessar console Rails

```bash
docker-compose exec web bin/rails console
```

### Rodar migrations

```bash
docker-compose exec web bin/rails db:migrate
```

### Rodar testes

```bash
docker-compose exec web bin/rails test
```

### Reiniciar a aplicação

```bash
docker-compose restart web
```

### Parar todos os containers

```bash
docker-compose down
```

### Reset completo (⚠️ apaga banco e volumes)

```bash
docker-compose down -v
docker-compose up -d
```

---

## Subdomínios (quando configurados)

O CatalystOps pode operar com subdomínios distintos:

- `register` → cadastro e onboarding
- `login` → autenticação
- `app` → painel principal
- `admin` → área administrativa

A configuração depende do ambiente e do proxy (ex: Nginx).

---

## Background jobs e Redis

O Redis é utilizado para:
- Jobs em background (ex: Sidekiq)
- Cache (quando habilitado)

Certifique-se de que o container `redis` esteja ativo antes de executar jobs.

---

## Deploy em produção (visão geral)

Em produção, o fluxo geral é:

1. Configurar servidor (Linux)
2. Instalar Docker e Docker Compose
3. Configurar `.env` com `RAILS_ENV=production`
4. Subir containers com `docker-compose up -d`
5. Rodar migrations
6. Configurar proxy reverso e HTTPS

> Recomenda-se uso de Nginx + Certbot para HTTPS.

---

## Problemas comuns

### Banco não conecta
- Aguarde alguns segundos após subir os containers
- Verifique `DATABASE_URL`

### Porta 3000 em uso
- Altere a porta no `docker-compose.yml`
- Ou finalize o processo que está usando a porta

### Alterações no código não refletem
```bash
docker-compose restart web
```

---

## Documentação

- Documentação do usuário final: `/docs_usuario_final`
- Documentação técnica: `/docs_tecnico`

---

## Licença e uso

Este projeto é de uso privado/comercial.
Consulte os **Termos de Uso** para mais informações.

---

## Observação final

Este README foi escrito para ser:
- Claro
- Reprodutível
- Amigável para novos desenvolvedores

Se algo não funcionar conforme esperado, revise o `docker-compose.yml`
e as variáveis de ambiente.
