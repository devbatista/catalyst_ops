# CatalystOps — README Técnico

Este documento é complementar à documentação do usuário final (Central de Ajuda).

## Stack (visão geral)
- Ruby on Rails
- PostgreSQL
- Hotwire (Turbo + Stimulus)
- Devise (autenticação)
- CanCanCan (autorização/permissões)
- Active Storage (anexos)

## Arquitetura (alto nível)
- Multi-tenant por empresa (sempre filtrar por `company`)
- Separação por subdomínios:
  - `register`: cadastro/assinatura inicial
  - `login`: login/recuperação
  - `app`: painel principal
  - `admin`: área administrativa

## Domínios funcionais principais
- Clientes
- Ordens de Serviço
- Técnicos/atribuições
- Agenda e eventos
- Relatórios
- Configurações (perfil/empresa)

## Observação para IA (RAG)
Os artigos estão organizados como **um fluxo por arquivo**, ideal para indexação e busca semântica.
