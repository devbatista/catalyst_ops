# Como exportar relatórios (CSV)

## Quando usar
Quando você quer levar os dados dos relatórios para fora do sistema (planilhas, análises externas ou arquivamento).

## Tipos de relatório
O sistema trabalha com quatro tipos de relatório:
- **Relatório de Clientes** (categoria Cadastros).
- **Relatório de Técnicos** (categoria Cadastros).
- **Ordens de Serviço por Período** (categoria Operacional).
- **Orçamentos por Período** (categoria Comercial).

Pela tela de **Relatórios**, a exportação gera os tipos **Ordens de Serviço** e **Orçamentos**, conforme a **Base** selecionada nos filtros.

## Passo a passo
1. Acesse **Relatórios**.
2. Em **Base**, escolha **Ordens de Serviço** ou **Orçamentos**.
3. Defina o período em **Data inicial** e **Data final**.
4. (Opcional) Ajuste **Status** e **Técnico** (apenas para OS).
5. Clique em **Aplicar** para conferir os dados na tela.
6. Clique em **Exportar CSV** (também estão disponíveis **Exportar XLSX** e **Exportar PDF**).

## O que acontece depois
- O sistema exibe a mensagem: "Exportação iniciada. O arquivo aparecerá em 'Relatórios gerados recentemente'."
- A geração do arquivo acontece **em segundo plano**: você pode continuar usando o sistema normalmente.
- A exportação passa pelos status: **Pendente** → **Processando** → **Finalizado** (ou **Falhou**, em caso de erro).
- O card **Relatórios gerados recentemente**, no fim da tela de Relatórios, lista os últimos 5 arquivos gerados com título, tipo, status e data de geração.
- O arquivo respeita os filtros aplicados no momento da exportação (base, período, agrupamento, status e técnico).
- O CSV traz os registros detalhados e, ao final, um resumo com os totais do período.

## Como baixar o arquivo
1. Na tela de **Relatórios**, vá até **Relatórios gerados recentemente**.
2. Enquanto o arquivo não estiver pronto, a linha mostra **Aguardando**; atualize a página para acompanhar o andamento.
3. Quando o status estiver **Finalizado**, clique em **Baixar**.

## Regra de período máximo
- O período máximo permitido para consulta/exportação é de **6 meses**.
- Se o período selecionado ultrapassar 6 meses, a data inicial é ajustada automaticamente para o limite permitido.

## Erros comuns
- Esperar o download imediato ao clicar em Exportar: a geração é assíncrona e o arquivo aparece na lista de gerados recentemente.
- Tentar baixar antes de o status ficar **Finalizado**: o sistema avisa que o arquivo ainda não está disponível para download.
- Exportar sem conferir os filtros: o arquivo sai com os filtros ativos na tela naquele momento.

## Dicas
- Aplique os filtros e confira os números na tela antes de exportar.
- Se a exportação ficar com status **Falhou**, revise o período e os filtros e tente novamente.
- Prefira CSV/XLSX para trabalhar os dados em planilha; use PDF quando o objetivo for apenas leitura/compartilhamento.
