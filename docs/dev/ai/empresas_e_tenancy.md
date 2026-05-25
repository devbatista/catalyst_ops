# Empresas E Tenancy

## Quando Ler Este Arquivo

Leia antes de alterar `Company`, qualquer query na área `app`, dados vinculados
a empresa, isolamento multi-tenant, onboarding de empresa ou acesso por
subdomínio.

## Visão Geral

`Company` é o tenant principal do CatalystOps. A maior parte dos dados de
negócio deve estar direta ou indiretamente ligada a `company_id`.

## Areas Relacionadas

- `register`: cria empresa, usuário inicial e assinatura.
- `app/gestor` e `app/tecnico`: operam sempre dentro de uma empresa.
- `admin`: pode enxergar dados globais da plataforma.
- Jobs e relatórios: devem deixar claro quando operam globalmente.

## Pontos De Entrada Importantes

- `app/models/company.rb`
- `app/models/user.rb`
- `app/models/client.rb`
- `app/models/order_service.rb`
- `app/models/budget.rb`
- `app/models/subscription.rb`
- `app/controllers/application_controller.rb`
- `app/controllers/app/*`
- `app/controllers/admin/companies_controller.rb`

## Regras De Negócio

- A área `app` deve derivar o escopo da empresa a partir do `current_user`.
- Queries globais na área `app` devem ser tratadas como falha até prova em
  contrário.
- Usuários, clientes, OS, orçamentos, tickets e assinaturas devem respeitar o
  tenant.
- A área `admin` pode consultar globalmente, mas deve deixar filtros e intenção
  explícitos.

## Estados E Transições

Este domínio não tem um único lifecycle central. Mudanças relevantes costumam
vir de assinatura, onboarding, ativação de usuários e configurações da empresa.

## Riscos Comuns

- Expor dados de outra empresa por `find(params[:id])` sem escopo.
- Usar associações globais quando existe associação por `current_user.company`.
- Misturar regras de admin com regras de app.
- Criar relatarios sem filtrar por empresa.

## Testes Recomendados

- Testes de controller/request garantindo isolamento entre empresas.
- Testes de authorization quando roles diferentes acessam dados do mesmo tenant.
- Testes de relatórios e dashboards com mais de uma empresa no banco.
