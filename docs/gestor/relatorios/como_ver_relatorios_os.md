# Como visualizar relatórios (OS e Orçamentos)

## Quando usar
Quando você quer analisar desempenho operacional e comercial por período.

## Passo a passo
1. Acesse **Relatórios**.
2. Em **Base**, escolha:
   - **Ordens de Serviço** para análise operacional.
   - **Orçamentos** para análise comercial.
3. Defina o período em **Data inicial** e **Data final**.
4. (Opcional) Ajuste:
   - **Agrupar por**: dia, semana ou mês.
   - **Status**.
   - **Técnico** (apenas para OS).
5. Clique em **Aplicar**.

## O que acontece depois
- A tela mostra indicadores (cards), gráficos e tabela detalhada conforme a base escolhida.
- Em OS, o gráfico de evolução mostra:
  - **OS criadas** (azul),
  - **OS finalizadas** (verde),
  - **OS canceladas** (vermelho, quando houver).
- Em Orçamentos, o gráfico mostra criados x aprovados.
- A tabela detalhada muda as colunas conforme a base (OS ou Orçamentos).

## Regra de período máximo
- O período máximo permitido para consulta/exportação é de **6 meses**.
- Se o período selecionado ultrapassar 6 meses, o sistema:
  1. Ajusta automaticamente a data inicial para o limite permitido.
  2. Exibe um **aviso visual** no topo da tela informando o ajuste.

## Erros comuns
- Relatório com poucos dados por filtro muito restrito.
- Comparar períodos diferentes sem padronizar a granularidade (dia/semana/mês).
- Esperar dados de técnico no relatório de Orçamentos (esse filtro vale apenas para OS).

## Dicas
- Use o mesmo agrupamento (ex.: mês) ao comparar períodos.
- Para operação, acompanhe **criadas x finalizadas x canceladas**.
- Para comercial, acompanhe **taxa de aprovação** e **ticket médio**.
- Evite intervalos longos sem necessidade; mantenha análise por recortes objetivos.
- Se sua empresa ativou **Criar OS sem orçamento** e/ou **OS simultâneas** em **Configurações**, considere esse contexto ao analisar volume e produtividade.
