# Auditoria E Operação

## Quando Ler Este Arquivo

Leia antes de alterar eventos de auditoria, logs administrativos, queries
operacionais, jobs de limpeza, runbooks, diagnóstico ou telas de monitoramento.

## Visão Geral

Auditoria e operação dão rastreabilidade a ações relevantes do sistema,
principalmente em domínios sensíveis como assinatura, suporte, usuários e OS.

## Areas Relacionadas

- `admin`: logs, métricas, coverage e diagnóstico.
- Jobs: ciclo de vida, limpeza e reconciliação.
- Queries operacionais: diagnósticos somente leitura.
- Runbooks em `docs/operacao/`.

## Pontos De Entrada Importantes

- `app/models/audit_event.rb`
- `app/services/audit/log.rb`
- `app/services/audit/event_logger.rb`
- `app/services/audit/auth_logger.rb`
- `app/services/audit/job_lifecycle_logger.rb`
- `app/services/audit/cleanup_old_events.rb`
- `app/services/audit/action_catalog.rb`
- `app/controllers/admin/logs_controller.rb`
- `app/queries/README.md`
- `docs/operacao/`

## Regras De Negócio

- Ações auditadas devem existir em `Audit::ActionCatalog`.
- Eventos devem incluir metadados suficientes para investigar o que mudou.
- Queries operacionais devem ser somente leitura.
- Logs administrativos podem ser globais, mas filtros por empresa, origem e
  período devem ser preservados.
- Jobs sensíveis devem registrar ciclo de vida quando o padrão local exigir.

## Estados E Transições

- `AuditEvent` registra ação, fonte, metadados e data de ocorrência.
- Eventos de reconciliação podem indicar sucesso, erro, divergência e resolução.
- Limpezas antigas devem respeitar retenção definida no código/configuração.

## Riscos Comuns

- Criar evento com action fora do catálogo.
- Remover metadados importantes para troubleshooting.
- Transformar query operacional em escrita.
- Quebrar filtros de logs admin.
- Registrar dado sensivel em log ou metadado.

## Testes Recomendados

- Testes de catálogo de ações.
- Testes de criação de eventos auditados em models/services sensíveis.
- Testes de filtros de logs administrativos.
- Testes de queries operacionais como leitura segura.
