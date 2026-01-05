module Cmd
  module Pdf
    class Create
      def initialize(order_service)
        @order_service = order_service
        @company = @order_service.company
        @client = @order_service.client
        @address = @client.addresses.first
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
          pdf.text("Ordem de Serviço #{@order_service.code}", align: :center, style: :bold)
        end
        pdf.fill_color("000000")
        pdf.move_down(5)

        # Tabela com logo, empresa e cliente (3 colunas)
        header_data = [
          [
            { content: "Insira sua logo aqui", align: :center, valign: :center },
            { content: "#{@company.name}
                        #{@company.formatted_document} || #{@company.formatted_phone}
                        #{@company.email}
                        #{@company.full_address}", align: :center, valign: :center },
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
            { content: @client.name, borders: [] },
            { content: "Documento:", align: :left, borders: [] },
            { content: @client.formatted_document, borders: [] },
          ],
          [
            { content: "Endereço:", align: :left, borders: [] },
            { content: @address.street, borders: [] },
            { content: "Nº:", align: :left, borders: [] },
            { content: @address.number, borders: [] },
          ],
          [
            { content: "Bairro:", align: :left, borders: [] },
            { content: @address.neighborhood, borders: [] },
            { content: "CEP:", align: :left, borders: [] },
            { content: @address.zip_code, borders: [] },
          ],
          [
            { content: "Telefone:", align: :left, borders: [] },
            { content: @client.formatted_phone, borders: [] },
            { content: "Email:", align: :left, borders: [] },
            { content: @client.email, borders: [] },
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
          [[@order_service.description]],
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
          ["Qtd", "Item", "Valor"],
        ]

        # Adiciona cada item da ordem de serviço
        @order_service.service_items.each do |item|
          data_items << [
            item.quantity,
            item.description,
            "R$ #{"%.2f" % item.unit_price}",
          ]
        end

        # Se quiser garantir pelo menos 5 linhas (completar com linhas em branco)
        while data_items.size < 6
          data_items << ["", "", ""]
        end

        pdf.table(data_items, header: true, width: pdf.bounds.width, cell_style: { size: 11, height: 28 })

        pdf.move_down(10)

        # Faixa laranja "Observações"
        pdf.fill_color(blue)
        pdf.fill_rectangle([0, pdf.cursor], pdf.bounds.width, 20)
        pdf.move_down(3)
        pdf.fill_color("FFFFFF")
        pdf.text("Observações:", align: :center, style: :bold)
        pdf.fill_color("000000")
        pdf.move_down(3)

        # Área para observações (tabela para garantir altura e alinhamento)
        pdf.table(
          [[@order_service.observations.presence || " "]],
          cell_style: {
            height: 80,
            borders: [],
          },
          width: pdf.bounds.width,
        )

        pdf.move_down(10)

        pdf.stroke_horizontal_line(pdf.bounds.left, pdf.bounds.right, at: pdf.cursor)

        # Rodapé com desconto e total (tabela para alinhar)
        rodape_data = [
          [
            { content: "Desconto:", borders: [] },
            { content: "", borders: [] },
            { content: "Total: #{@order_service.formatted_total_value}", align: :right, borders: [] },
          ],
        ]
        pdf.table(rodape_data, cell_style: { borders: [] }, width: pdf.bounds.width)
        pdf.move_down(5)

        # Faixa laranja garantia
        pdf.fill_color(blue)
        pdf.fill_rectangle([0, pdf.cursor], pdf.bounds.width, 20)
        pdf.move_down(3)
        pdf.fill_color("FFFFFF")
        pdf.text("Este serviço prestado possui garantia de X dias após a entrega.", align: :center)
        pdf.fill_color("000000")
        pdf.move_down(20)

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
