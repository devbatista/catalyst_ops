# CatalystOps - Instruções Para Agentes De IA

Este arquivo orienta agentes de IA que atuam neste repositório.

Antes de alterar código, leia este arquivo e depois leia os arquivos relevantes
em `docs/dev/ai/`.

## Contexto Geral

CatalystOps é uma aplicação Rails SaaS multi-tenant para empresas prestadoras de
serviços técnicos.

## Regras Gerais

- Preservar isolamento por `company_id`.
- Tratar queries globais na área `app` como suspeitas.
- Respeitar permissões centralizadas em `app/models/ability.rb`.
- Não alterar assinatura, cobrança, permissões ou lifecycle de OS sem testes.
- Nunca esquecer de acentuar corretamente textos, documentação, labels,
  mensagens de usuário e conteúdo em português.
- Preferir padrões existentes do projeto antes de criar novas abstrações.
- Consultar `README_TECNICO.md` quando a tarefa envolver arquitetura,
  boundaries de domínio, autenticação, autorização ou operação.

## Mapa De Contexto

- Índice geral: `docs/dev/ai/00_indice.md`
- Assinaturas e cobrança: `docs/dev/ai/assinaturas.md`
- Empresa e tenancy: `docs/dev/ai/empresas_e_tenancy.md`
- Usuários e permissões: `docs/dev/ai/usuarios_e_permissoes.md`
- Ordens de serviço: `docs/dev/ai/ordens_de_servico.md`
- Orçamentos: `docs/dev/ai/orcamentos.md`
- Clientes: `docs/dev/ai/clientes.md`
- Agenda e atribuições: `docs/dev/ai/agenda_e_atribuicoes.md`
- Suporte e base de conhecimento: `docs/dev/ai/suporte_e_base_conhecimento.md`
- Financeiro e relatórios: `docs/dev/ai/financeiro_e_relatorios.md`
- Integrações e webhooks: `docs/dev/ai/integracoes_e_webhooks.md`
- Auditoria e operação: `docs/dev/ai/auditoria_e_operacao.md`
