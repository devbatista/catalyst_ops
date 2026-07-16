# CatalystOps — Documento de Vendas

> Material interno de apoio comercial. Todos os dados de planos, limites e
> funcionalidades foram extraídos diretamente do sistema em produção
> (código-fonte e seeds). Última atualização: julho/2026.

## O Que É

CatalystOps é um SaaS de gestão de ordens de serviço para empresas
prestadoras de serviços técnicos (assistências, manutenção, instalação,
field service em geral). Centraliza orçamentos, ordens de serviço, agenda de
técnicos, clientes, financeiro e suporte em um único lugar — com acesso web
e app mobile para o técnico em campo.

## Público-Alvo

- Assistências técnicas e empresas de manutenção/instalação de pequeno e
  médio porte.
- Operações com 1 a dezenas de técnicos em campo.
- Dono/gestor que hoje controla OS em planilha, papel ou WhatsApp e perde
  faturamento por falta de organização.

## Proposta de Valor (elevator pitch)

"Do orçamento ao pagamento em um só fluxo: você cria o orçamento, o cliente
aprova online sem precisar de login, a OS é gerada automaticamente, o técnico
recebe na agenda e no celular, e o financeiro mostra o que foi realizado e o
que está pendente."

## Funcionalidades Por Módulo

### Orçamentos com aprovação online (diferencial-chave)
- Criação de orçamento com itens, valores e prazo de validade.
- Envio por e-mail com link exclusivo: o cliente final **aprova ou rejeita
  online, sem login e sem instalar nada**.
- Aprovação gera a Ordem de Serviço automaticamente, com os itens copiados.
- PDF do orçamento disponível para o cliente baixar.

### Ordens de Serviço (ciclo completo)
- Status de ponta a ponta: pendente → agendada → em andamento → concluída →
  finalizada (com cancelamento e detecção automática de atraso).
- Itens de serviço (serviços, peças, materiais) com valores.
- Anexos (fotos, laudos, comprovantes).
- PDF da OS com envio por e-mail ao cliente.
- Recibos de entrada e devolução de equipamento do cliente.

### Agenda e técnicos
- Calendário da operação (dia/semana) e agenda por técnico.
- Detecção de conflito de horário e aviso de OS simultâneas.
- Permissões por papel: gestor administra; técnico vê e executa só o que é
  dele.

### App mobile (API dedicada)
- Login seguro no celular; o técnico vê dashboard, agenda e suas OS.
- Atualiza status, adiciona observações e envia fotos direto do atendimento.

### Financeiro e relatórios
- Visão de faturamento realizado × pendente por itens de OS.
- Relatórios de OS e orçamentos por período (SLA, tendências, taxa de
  aprovação, ticket médio).
- Exportação em CSV, XLSX e PDF, processada em segundo plano.

### Personalização de PDF (planos Profissional e Enterprise)
- Logo e cores da empresa nos PDFs de OS e orçamento — documento com a marca
  do cliente, não a nossa.

### Suporte e base de conhecimento
- Central de ajuda com artigos por perfil (gestor e técnico).
- Tickets de suporte com acompanhamento.
- Contato rápido (WhatsApp + e-mail) nos planos Profissional e Enterprise.

### Segurança e conformidade
- Isolamento total de dados por empresa (multi-tenant).
- Trilha de auditoria de eventos críticos, com política de retenção (LGPD).
- Aceite de termos com registro de IP, usuário e data.

## Planos e Preços

Fonte: seeds/configuração de planos do sistema. Limites de OS e orçamentos
são **mensais** (mês corrente). "Ilimitado" = sem restrição.

| | **Starter** | **Básico** | **Profissional** | **Enterprise** |
|---|---|---|---|---|
| **Preço/mês** | R$ 0 | R$ 99 | R$ 199 | R$ 399 |
| **Técnicos** | 1 (o próprio gestor) | 1 | 6 | Ilimitado |
| **OS/mês** | 3 | 15 | 60 | 200 |
| **Orçamentos/mês** | 3 | 15 | 60 | 200 |
| **Suporte** | Base de conhecimento | E-mail (tickets) | Prioritário + Contato rápido | Dedicado + Contato rápido |
| **PDF personalizado** | — | — | ✔ | ✔ |

### Regras comerciais do sistema
- **Starter é gratuito de verdade**: sem cartão, sem cobrança, sem prazo de
  expiração. Porta de entrada para experimentar o produto.
- **Upgrade self-service**: quem está no Starter contrata plano pago direto
  no painel (Configurações > Assinatura), sem falar com ninguém.
- **Só existe upgrade entre pagos** (Básico → Profissional → Enterprise);
  não há downgrade pelo painel.
- **Formas de pagamento**: PIX, boleto e cartão de crédito (Mercado Pago).
- **Cupons**: desconto (percentual ou valor fixo) ou período de teste
  (trial). Um cupom por empresa a cada 12 meses. Cupom de desconto não se
  aplica a cadastro com cartão de crédito.
- Cancelamento de plano pago é agendado para o fim do período já pago, com
  opção de reativar antes de efetivar.

## Argumentos de Venda Por Persona

### Dono/gestor sobrecarregado
- "Quantas OS você perdeu esse mês por esquecer de agendar ou cobrar?"
- Dashboard com visão do dia, OS atrasadas destacadas automaticamente,
  faturamento pendente visível.

### Operação em crescimento (contratando técnicos)
- Agenda por técnico com detecção de conflito.
- Permissões prontas: técnico não vê financeiro nem dados de outros
  atendimentos.
- App mobile: técnico novo produz no primeiro dia.

### Empresa que quer profissionalizar a imagem
- Cliente final aprova orçamento em página profissional, sem login.
- PDF com logo e cores da empresa (Profissional/Enterprise).
- Recibos de entrada/devolução de equipamento.

## Objeções Comuns e Respostas

| Objeção | Resposta |
|---|---|
| "É caro." | Comece no Starter gratuito — 3 OS/mês sem pagar nada. O Básico custa R$ 99: uma OS recuperada por mês já paga o sistema. |
| "Meu técnico não vai usar." | O app mobile mostra só o que ele precisa: agenda e OS dele. Atualizar status e mandar foto é mais fácil que responder WhatsApp. |
| "Já uso planilha." | Planilha não avisa OS atrasada, não deixa o cliente aprovar orçamento online e não gera OS sozinha. |
| "E se eu quiser sair?" | Sem fidelidade: o cancelamento vale até o fim do período pago e os relatórios exportam seus dados em CSV/XLSX. |
| "Meus dados ficam seguros?" | Isolamento por empresa, auditoria de eventos críticos e conformidade LGPD (retenção e aceite de termos registrados). |

## Jornada do Cliente (funil)

1. **Cadastro gratuito** no Starter (sem cartão) → onboarding guiado com
   checklist de primeiros passos.
2. **Ativação**: cria cliente, orçamento e primeira OS (o checklist conduz).
3. **Limite como gatilho**: ao bater 3 OS/orçamentos no mês, o sistema
   oferece upgrade no próprio painel.
4. **Conversão self-service**: escolhe plano, paga com PIX/boleto/cartão,
   acesso liberado na confirmação.
5. **Expansão**: crescimento de equipe leva Básico → Profissional →
   Enterprise (limite de técnicos é o principal gatilho).

## O Que NÃO Prometer (limites reais do produto hoje)

- Não há downgrade de plano pelo painel.
- Não há exportação de cadastro de clientes/técnicos pela tela de
  relatórios (somente OS e orçamentos).
- Contato rápido (WhatsApp) só existe em Profissional e Enterprise.
- Starter não abre ticket de suporte (só base de conhecimento).
- Sem integração com outros gateways além do Mercado Pago.
- Sem app publicado em loja — o mobile é via API/app próprio (confirmar
  status de publicação antes de prometer).

## Documentos Relacionados

- Matriz técnica de planos e assinaturas: `docs/dev/ai/assinaturas.md`
- Upgrade pelo painel: `docs/gestor/conta/como_fazer_upgrade_de_plano.md`
- Aprovação de orçamento pelo cliente: `docs/gestor/orcamentos/como_cliente_aprova_orcamento.md`
- Personalização de PDF: `docs/gestor/conta/como_personalizar_pdf.md`
