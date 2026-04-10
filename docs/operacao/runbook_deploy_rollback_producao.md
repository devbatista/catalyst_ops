# Runbook de Deploy/Rollback em Produção

Este runbook cobre os itens do checklist:

- Documentar passo a passo de deploy em produção.
- Documentar rollback para imagem/tag anterior.
- Definir responsável e critério de rollback em incidente.

## 1) Responsáveis e papéis

- **Responsável técnico do deploy (owner da execução):**
  pessoa de engenharia on-call no momento da janela.
- **Aprovador de negócio (go/no-go):**
  responsável de produto/operação.
- **Suporte/monitoramento:**
  pessoa acompanhando logs e sinais pós-deploy por 30 minutos.

Regra operacional:

- deploy só inicia com owner + aprovador definidos.
- qualquer rollback deve ser decidido pelo owner técnico e comunicado ao aprovador.

## 2) Critérios de Go/No-Go e rollback

### Go (seguir deploy)

- CI da `main` verde.
- sem incidentes ativos críticos.
- backup de banco confirmado.
- janela de deploy em andamento com plantão ativo.

### Rollback obrigatório (gatilho)

Executar rollback se ocorrer qualquer condição abaixo após deploy:

- indisponibilidade da aplicação por mais de 5 minutos.
- erro 5xx sustentado em rotas críticas (login, dashboard, OS, pagamentos).
- falha de migração sem correção imediata e segura.
- Sidekiq parado ou fila crítica sem consumo por mais de 10 minutos.
- falha em fluxo crítico de negócio (ex.: criação/atualização de OS, webhook de pagamento).

## 3) Pré-checklist antes do deploy

1. Confirmar último backup válido do banco.
2. Confirmar variáveis de ambiente de produção (`.env`) presentes.
3. Confirmar status dos serviços:
   - `docker compose ps`
4. Confirmar zero incidentes críticos abertos.
5. Avisar início da janela para time interno.

## 4) Deploy padrão (automático via GitHub Actions)

Quando há push na `main`, o workflow
`.github/workflows/deploy.yml` executa `bin/deploy` no servidor.

Resumo do que `bin/deploy` faz:

1. escreve/atualiza `.env` de produção no servidor.
2. `git fetch` + `git pull --ff-only` da branch alvo.
3. calcula arquivos alterados e decide rebuild/restart.
4. executa `docker compose run --rm web bundle exec rails db:migrate`.
5. valida extensão `vector` no banco.
6. reinicia `web`, `sidekiq` e `nginx` quando necessário.

Validação pós-deploy (imediata):

1. `docker compose ps`
2. `docker compose logs --since=10m web`
3. `docker compose logs --since=10m sidekiq`
4. smoke rápido em:
   - login
   - dashboard app
   - listagem de OS
   - criação/edição simples de OS

## 5) Deploy manual (contingência)

No servidor:

```bash
cd /opt/catalyst_ops
git fetch origin main
git checkout main
git pull --ff-only origin main
bash /opt/catalyst_ops/bin/deploy
```

Use deploy manual quando o workflow automático falhar por problema externo de CI/SSH.

## 6) Rollback para versão/tag anterior

Objetivo: voltar rapidamente para uma versão estável já conhecida.

### 6.1 Rollback por tag (preferencial)

```bash
cd /opt/catalyst_ops
git fetch --all --tags
git checkout <TAG_ESTAVEL>
bash /opt/catalyst_ops/bin/deploy
```

Exemplo: `git checkout v2026.04.10-1`

### 6.2 Rollback por commit

```bash
cd /opt/catalyst_ops
git fetch --all
git checkout <SHA_ESTAVEL>
bash /opt/catalyst_ops/bin/deploy
```

### 6.3 Pós-rollback

1. Validar serviços e logs (`web`, `sidekiq`, `nginx`).
2. Rodar smoke rápido das rotas críticas.
3. Registrar incidente com:
   - horário do rollback
   - motivo/gatilho
   - versão de origem e versão de destino
   - próximo plano de correção

## 7) Atenção com migrations em rollback

- Se migration foi aplicada e é **irreversível**, rollback de código pode não ser suficiente.
- Nesses casos:
  - manter versão estável compatível com o schema atual, ou
  - executar plano de restauração de banco (conforme política de backup/restore).
- Nunca executar `db:rollback` diretamente em produção sem validação prévia da migration.

## 8) Comunicação de incidente

Ao acionar rollback:

1. comunicar imediatamente no canal interno de incidentes.
2. informar status a cada 10 minutos até estabilização.
3. abrir post-mortem com causa raiz e ações preventivas.
