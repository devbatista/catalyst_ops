# Como gerenciar comprovantes de produto (recebimento e devolução)

## Quando usar
Quando a OS envolve entrada e saída de produto/equipamento do cliente (ex.: notebook para conserto).

## Objetivo do fluxo
- Registrar formalmente o **recebimento** do produto.
- Registrar formalmente a **devolução** do produto.
- Manter rastreabilidade de emissão e envio ao cliente.

## Regras principais
- Apenas **gestor** pode acessar e operar os comprovantes.
- **Recebimento de produto**:
  - tem tela própria;
  - permite salvar dados, gerar PDF e enviar ao cliente.
- **Devolução de produto**:
  - disponível para OS `concluída`, `finalizada` ou `cancelada`;
  - usa os dados já registrados no recebimento (sem formulário de edição).
- Envio exige cliente com e-mail cadastrado.

## Passo a passo — Recebimento de produto
1. Abra a OS.
2. Clique em **Recebimento de produto**.
3. Cadastre os itens recebidos (item, marca/modelo, série, qtd opcional, estado, defeito, acessórios).
4. Clique em **Salvar dados do comprovante**.
5. Clique em **Gerar PDF de recebimento de produto** para emitir.
6. Clique em **Enviar recebimento de produto** para envio por e-mail.

## Passo a passo — Devolução de produto
1. Abra a OS (status concluída/finalizada/cancelada).
2. Clique em **Devolução de produto**.
3. Revise os itens exibidos na tela.
4. Clique em **Gerar PDF de devolução de produto**.
5. Clique em **Enviar devolução de produto**.

## Controle de emissão e envio
Nas telas de comprovante existe um bloco no topo com:
- **Último emitido em**: data/hora da última geração de PDF.
- **Último enviado em**: data/hora do último envio ao cliente.

Esses dados são lidos do histórico de auditoria (`AuditEvents`).

## Auditoria registrada
- `order_service.receipt.generated`
- `order_service.receipt.sent`
- `order_service.return_receipt.generated`
- `order_service.return_receipt.sent`

## Motivos de desenho do fluxo
- O cadastro de produto fica no **comprovante de recebimento** (não no formulário geral da OS), porque a origem desses dados é a entrada física do item.
- A devolução usa os mesmos dados para evitar divergência entre “o que entrou” e “o que saiu”.
- Separar `salvar`, `gerar PDF` e `enviar` melhora conferência operacional e rastreabilidade.

## Erros comuns
- Tentar enviar comprovante sem e-mail do cliente.
- Tentar abrir devolução em OS fora dos status permitidos.
- Não revisar os itens recebidos antes de gerar/envio.
