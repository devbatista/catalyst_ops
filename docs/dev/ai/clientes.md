# Clientes

## Quando Ler Este Arquivo

Leia antes de alterar cadastro, edição, busca, documentos, endereços, histórico
de clientes ou relações com OS e orçamentos.

## Visão Geral

`Client` representa o cliente final atendido pela empresa usuária. Ele é base
para ordens de serviço, orçamentos, endereços e histórico operacional.

## Áreas Relacionadas

- `app/gestor`: cadastro, edição, busca e histórico.
- OS e orçamentos: dependem do cliente.
- Relatórios: podem filtrar ou agrupar por cliente.

## Pontos De Entrada Importantes

- `app/models/client.rb`
- `app/models/address.rb`
- `app/models/order_service.rb`
- `app/models/budget.rb`
- `app/controllers/app/clients_controller.rb`

## Regras De Negócio

- Cliente pertence a uma `Company`.
- Documento e email devem respeitar unicidade dentro da empresa.
- Endereços pertencem ao cliente e devem manter formato válido.
- Histórico de cliente deve ser restrito a OS e orçamentos da mesma empresa.

## Estados E Transições

Este domínio não tem lifecycle complexo. O cuidado principal é manter dados de
cadastro, endereços e relações históricas consistentes.

## Riscos Comuns

- Validar documento ou email globalmente quando a regra é por empresa.
- Apagar cliente com dependências operacionais sem entender impactos.
- Buscar histórico sem escopo por empresa.
- Quebrar formatos de telefone, documento, CEP ou UF.

## Testes Recomendados

- Testes de model para validações e unicidade por empresa.
- Testes de controller/request para CRUD por gestor.
- Testes de busca e histórico com dados de mais de uma empresa.
