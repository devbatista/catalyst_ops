# Usuários E Permissões

## Quando Ler Este Arquivo

Leia antes de alterar autenticação, roles, `Ability`, permissões, cadastro de
técnicos, promoção de usuários, escopo de visibilidade ou regras de acesso.

## Visão Geral

O projeto usa Devise para autenticação e CanCanCan para autorização. `User` é o
entrypoint de contexto da aplicação protegida, e `Ability` concentra as regras
reais de permissão.

## Áreas Relacionadas

- `login`: autenticação e recuperação de credenciais.
- `register`: cadastro inicial.
- `app/gestor`: administra usuários da empresa.
- `app/tecnico`: executa OS dentro das permissões.
- `admin`: opera a plataforma.

## Pontos De Entrada Importantes

- `app/models/user.rb`
- `app/models/ability.rb`
- `app/controllers/sessions_controller.rb`
- `app/controllers/app/technicians_controller.rb`
- `app/controllers/admin/users_controller.rb`
- `config/routes/login.rb`
- `config/routes/register.rb`

## Regras De Negócio

- Roles principais: `admin`, `gestor` e `tecnico`.
- `current_user` é a fonte primária de contexto autenticado.
- Permissões de backend devem ficar em `Ability`; esconder botão na view não é
  autorização suficiente.
- Técnicos devem ver apenas o que sua role, empresa e atribuições permitem.
- A semântica `can_be_technician` pode fazer um usuário entrar em fluxos de
  técnico mesmo sem role pura de técnico.

## Estados E Transições

- Usuários podem estar ativos ou inativos.
- Promoção ou alteração de role pode mudar acesso a dados e ações.
- Cadastro e confirmação passam pelos fluxos do Devise e do onboarding.

## Riscos Comuns

- Criar regra na controller e esquecer `Ability`.
- Liberar dado por role sem conferir `company_id`.
- Quebrar usuários com `can_be_technician`.
- Tratar `admin` como usuário de empresa comum.

## Testes Recomendados

- Testes de `Ability` para cada role.
- Testes de request/controller para acesso negado e permitido.
- Testes com duas empresas para evitar vazamento de dados.
- Testes de promoção, remoção e inativação de técnicos.
