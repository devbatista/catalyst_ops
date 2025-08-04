module Cmd
  module Pdf
    class Create
      def initialize(order_service)
        @order_service = order_service
      end

      def generate_pdf_data
        blue = "5191cd"
        pdf = PdfGenerator.new

        pdf.stroke_rectangle(
          [pdf.bounds.left, pdf.bounds.top],
          pdf.bounds.width,
          pdf.bounds.height
        )

        # Faixa laranja com título centralizado
        pdf.fill_color(blue)
        pdf.fill_rectangle([0, pdf.cursor], pdf.bounds.width, 35)
        pdf.move_down(7)
        pdf.font_size(26) do
          pdf.fill_color("FFFFFF")
          pdf.text("Ordem de Serviço 001", align: :center, style: :bold)
        end
        pdf.fill_color("000000")
        pdf.move_down(5)

        # Tabela com logo, empresa e cliente (3 colunas)
        header_data = [
          [
            { content: "Insira sua logo aqui", align: :center, valign: :center },
            { content: "eGestor - Sistema de Gestão Empresarial
                        0800 603 3336
                        egestor@egestor.com.br
                        Rua do Acampamento nº 380 Salas 1, 2 e 3 - Centro", align: :center, valign: :center },
          ],
        ]
        pdf.table(
          header_data,
          cell_style: {
            borders: [:bottom],
            border_width: 1,
            border_color: "000000",
            padding: [0, 8, 10, 8],
            size: 11,
          },
          width: pdf.bounds.width,
        )

        # Tabela com dados do cliente (abaixo da linha)
        client_data = [
          [
            { content: "Cliente:", align: :left, borders: [] },
            { content: "", borders: [] },
            { content: "CPF:", align: :left, borders: [] },
            { content: "", borders: [] },
          ],
          [
            { content: "Endereço:", align: :left, borders: [] },
            { content: "", borders: [] },
            { content: "Nº:", align: :left, borders: [] },
            { content: "", borders: [] },
          ],
          [
            { content: "Bairro:", align: :left, borders: [] },
            { content: "", borders: [] },
            { content: "CEP:", align: :left, borders: [] },
            { content: "", borders: [] },
          ],
          [
            { content: "Telefone:", align: :left, borders: [] },
            { content: "", borders: [] },
            { content: "Email:", align: :left, borders: [] },
            { content: "", borders: [] },
          ],
        ]
        pdf.table(
          client_data,
          cell_style: {
            borders: [],
            size: 11,
            padding: [4, 8, 4, 8],
          },
          width: pdf.bounds.width,
        )

        # Faixa laranja "Descrição do Serviço"
        pdf.fill_color(blue)
        pdf.fill_rectangle([0, pdf.cursor], pdf.bounds.width, 20)
        pdf.move_down(3)
        pdf.fill_color("FFFFFF")
        pdf.text("Descrição do Serviço:", align: :center, style: :bold)
        pdf.fill_color("000000")
        pdf.move_down(3)

        # Área em branco para descrição (tabela para garantir altura)
        pdf.table(
          [[""]],
          cell_style: {
            height: 80,
            borders: [],
          },
          width: pdf.bounds.width,
        )

        # Faixa laranja "Itens de serviço"
        pdf.fill_color(blue)
        pdf.fill_rectangle([0, pdf.cursor], pdf.bounds.width, 20)
        pdf.move_down(3)
        pdf.fill_color("FFFFFF")
        pdf.text("Itens de serviço:", align: :center, style: :bold)
        pdf.fill_color("000000")
        pdf.move_down(10)

        # Tabela de produtos (linhas em branco)
        data_items = [
          ["Qntd.", "Produtos", "Valor"],
          ["", "", ""],
          ["", "", ""],
          ["", "", ""],
          ["", "", ""],
          ["", "", ""],
        ]
        pdf.table(data_items, header: true, width: pdf.bounds.width, cell_style: { size: 11, height: 28 })

        pdf.move_down(10)

        # Faixa laranja "Observações"
        pdf.fill_color(blue)
        pdf.fill_rectangle([0, pdf.cursor], pdf.bounds.width, 20)
        pdf.move_down(3)
        pdf.fill_color("FFFFFF")
        pdf.text("Observações:", align: :center, style: :bold)
        pdf.fill_color("000000")
        pdf.move_down(80)

        pdf.stroke_horizontal_line(pdf.bounds.left, pdf.bounds.right, at: pdf.cursor)

        # Rodapé com desconto e total (tabela para alinhar)
        rodape_data = [
          [
            { content: "Desconto:", borders: [] },
            { content: "", borders: [] },
            { content: "Total: R$ 0,00", align: :right, borders: [] },
          ],
        ]
        pdf.table(rodape_data, cell_style: { borders: [] }, width: pdf.bounds.width)
        pdf.move_down(5)

        # Faixa laranja garantia
        pdf.fill_color(blue)
        pdf.fill_rectangle([0, pdf.cursor], pdf.bounds.width, 20)
        pdf.move_down(3)
        pdf.fill_color("FFFFFF")
        pdf.text("Este serviço prestado possui garantia de 15 dias após a entrega.", align: :center)
        pdf.fill_color("000000")
        pdf.move_down(20)

        # # Assinaturas (tabela para linhas)
        # assinatura_data = [
        #   [
        #     { content: "", borders: [], height: 70 },
        #     { content: "", borders: [], height: 70 },
        #   ],
        #   [
        #     { content: "Cliente", borders: [:top], border_width: 1, border_color: "000000", padding_left: 30 },
        #     { content: "Responsável", borders: [:top], border_width: 1, border_color: "000000", padding_right: 30 },
        #   ],
        # ]
        # pdf.table(
        #   assinatura_data,
        #   cell_style: {
        #     width: pdf.bounds.width / 2,
        #     align: :center,
        #     valign: :bottom,
        #     size: 14,
        #   },
        #   position: :center,
        # )

        padding = 24
        pdf.bounding_box([pdf.bounds.left + padding, 80], width: pdf.bounds.width - 2 * padding, height: 80) do
          y = pdf.cursor - 30
          line_width = (pdf.bounds.width - 2 * padding) / 2.5
          gap = 10 # distância vertical entre linha e texto

          # Linha para Cliente (esquerda)
          pdf.stroke_horizontal_line(pdf.bounds.left, pdf.bounds.left + line_width, at: y)
          # Linha para Responsável (direita)
          pdf.stroke_horizontal_line(pdf.bounds.right - line_width, pdf.bounds.right, at: y)

          # Texto abaixo das linhas, centralizado em relação à linha
          pdf.text_box(
            "Cliente",
            at: [pdf.bounds.left, y - gap],
            width: line_width,
            height: 20,
            align: :center,
            size: 14,
          )
          pdf.text_box(
            "Responsável",
            at: [pdf.bounds.right - line_width, y - gap],
            width: line_width,
            height: 20,
            align: :center,
            size: 14,
          )
        end

        pdf.render
      end

      def attach_pdf
        pdf_data = generate_pdf_data
        @order_service.attachments.attach(
          io: StringIO.new(pdf_data),
          filename: "ordem_servico_#{@order_service.id}.pdf",
          content_type: "application/pdf",
        )
      end
    end
  end
end
