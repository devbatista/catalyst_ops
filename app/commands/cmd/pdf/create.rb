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
        pdf = PdfGenerator.new
        accent = "3B82F6"
        border = "D9DDE3"
        soft_bg = "F3F5F7"
        text = "111827"
        page_width = pdf.bounds.width

        pdf.table(
          [[
            {
              content: "<b>Ordem de Serviço</b>\n<font size='2'> </font>\n<font size='10' color='C8CDD3'>Detalhes completos da execução</font>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              size: 16,
              padding: [12, 14, 12, 14],
              valign: :center
            },
            {
              content: "<b>OS ##{@order_service.code}</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :center,
              valign: :center,
              size: 11,
              padding: [12, 10, 12, 10]
            }
          ]],
          width: page_width,
          column_widths: [ page_width * 0.8, page_width * 0.2 ],
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )
        pdf.move_down(12)

        pdf.table(
          [[
            {
              content: "<b>Dados da Empresa</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :center,
              size: 10,
              padding: [5, 8, 5, 8]
            }
          ]],
          width: page_width,
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )
        pdf.table(
          [[
            "<b>Empresa:</b> #{safe(@company&.name)}\n" \
            "<b>Documento:</b> #{safe(@company&.formatted_document)}\n" \
            "<b>Telefone:</b> #{safe(@company&.formatted_phone)}\n" \
            "<b>Email:</b> #{safe(@company&.email)}\n" \
            "<b>Endereço:</b> #{safe(@company&.full_address)}"
          ]],
          width: page_width,
          cell_style: { inline_format: true, size: 10, padding: [8, 10, 8, 10], border_color: border, background_color: "FFFFFF" }
        )
        pdf.move_down(10)

        pdf.table(
          [[
            {
              content: "<b>Dados do Cliente</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :center,
              size: 10,
              padding: [5, 8, 5, 8]
            }
          ]],
          width: page_width,
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )

        info_data = [
          ["Cliente", safe(@client&.name), "Documento", safe(@client&.formatted_document)],
          ["Título", safe(@order_service.title), "Status", @order_service.status.to_s.humanize],
          ["Criada em", format_datetime(@order_service.created_at), "Agendada para", format_datetime(@order_service.scheduled_at)],
          ["Previsão de término", format_datetime(@order_service.expected_end_at), "Telefone", safe(@client&.formatted_phone)],
          ["E-mail", safe(@client&.email), "Código da OS", @order_service.code.to_s],
          ["Endereço", client_full_address, "Bairro / CEP", client_district_and_zip]
        ]

        pdf.table(
          info_data,
          width: page_width,
          cell_style: { size: 10, padding: [6, 8, 6, 8], border_color: border },
          column_widths: [page_width * 0.2, page_width * 0.3, page_width * 0.2, page_width * 0.3]
        ) do |table|
          table.columns(0).font_style = :bold
          table.columns(2).font_style = :bold
          table.columns(0).background_color = soft_bg
          table.columns(2).background_color = soft_bg
        end
        pdf.move_down(10)

        pdf.table(
          [[
            {
              content: "<b>Descrição do Serviço</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :center,
              size: 10,
              padding: [5, 8, 5, 8]
            }
          ]],
          width: page_width,
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )
        pdf.table(
          [[safe(@order_service.description)]],
          width: page_width,
          cell_style: { size: 10, padding: [10, 10, 10, 10], border_color: border, background_color: "FFFFFF" }
        )
        pdf.move_down(12)

        pdf.table(
          [[
            {
              content: "<b>Itens de Serviço</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :center,
              size: 10,
              padding: [5, 8, 5, 8]
            }
          ]],
          width: page_width,
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )

        item_rows = [[ "Descrição", "Qtd.", "Valor unitário", "Total" ]]
        @order_service.service_items.order(:created_at).each do |item|
          unit_price = item.unit_price.to_d
          quantity = item.quantity.to_d
          item_rows << [
            safe(item.description),
            item.quantity.to_s,
            brl(unit_price),
            brl(quantity * unit_price)
          ]
        end

        item_rows << [ "Sem itens cadastrados", "-", "-", "-" ] if item_rows.size == 1

        pdf.table(
          item_rows,
          header: true,
          width: page_width,
          cell_style: { size: 10, padding: [8, 10, 8, 10], border_color: border, inline_format: true },
          row_colors: [ "FFFFFF", soft_bg ],
          column_widths: [page_width * 0.42, page_width * 0.12, page_width * 0.23, page_width * 0.23]
        ) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = "E9EDF2"
          table.row(0).text_color = "1F2937"
          table.columns(1..3).align = :right
          table.rows(1..-1).columns(0).align = :left
          table.cells.border_width = 1
        end
        pdf.move_down(10)
        totals_data = [
          [{ content: "Subtotal: #{brl(@order_service.subtotal_value)}", align: :right }],
          [{ content: "Desconto: #{brl(@order_service.discount_amount)}", align: :right }],
          [{ content: "Total: #{brl(@order_service.total_value)}", align: :right, font_style: :bold }]
        ]
        pdf.table(
          totals_data,
          width: page_width,
          cell_style: { size: 12, padding: [6, 10, 6, 10], border_color: border, background_color: "F8FAFC" }
        )

        if @order_service.discount_applied? && @order_service.discount_reason.present?
          pdf.move_down(8)
          pdf.table(
            [[{ content: "Motivo do desconto: #{safe(@order_service.discount_reason)}", align: :left }]],
            width: page_width,
            cell_style: { size: 10, padding: [6, 10, 6, 10], border_color: border, background_color: "FFFFFF" }
          )
        end

        if @order_service.observations.present?
          pdf.move_down(12)
          pdf.table(
            [[
              {
                content: "<b>Observações</b>",
                inline_format: true,
                background_color: accent,
                text_color: "FFFFFF",
                border_color: accent,
                align: :center,
                size: 10,
                padding: [5, 8, 5, 8]
              }
            ]],
            width: page_width,
            cell_style: { borders: [:top, :bottom, :left, :right] }
          )
          pdf.table(
            [[safe(@order_service.observations)]],
            width: page_width,
            cell_style: { size: 10, padding: [8, 10, 8, 10], border_color: border, background_color: "FFFFFF" }
          )
        end

        signature_width = (page_width - 40) / 2.0
        signature_area_height = 28
        signature_bottom_padding = 8
        signature_top = pdf.bounds.bottom + signature_area_height + signature_bottom_padding

        pdf.bounding_box([pdf.bounds.left, signature_top], width: page_width, height: signature_area_height) do
          y = pdf.cursor
          pdf.stroke_horizontal_line(pdf.bounds.left, pdf.bounds.left + signature_width, at: y)
          pdf.stroke_horizontal_line(pdf.bounds.right - signature_width, pdf.bounds.right, at: y)
          pdf.move_down(6)
          pdf.table(
            [[
              { content: "Cliente", align: :center, borders: [] },
              { content: "Responsável", align: :center, borders: [] }
            ]],
            width: page_width,
            column_widths: [page_width / 2.0, page_width / 2.0],
            cell_style: { size: 10, border_color: border, padding: [0, 0, 0, 0] }
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

      private

      def safe(value)
        value.to_s.strip.presence || "-"
      end

      def format_datetime(value)
        return "-" if value.blank?

        I18n.l(value, format: :short)
      end

      def client_full_address
        street = safe(@address&.street)
        number = safe(@address&.number)
        city = safe(@address&.city)
        state = safe(@address&.state)
        "#{street}, #{number} - #{city}/#{state}"
      end

      def client_district_and_zip
        neighborhood = safe(@address&.neighborhood)
        zip = safe(@address&.zip_code)
        "#{neighborhood} / #{zip}"
      end

      def brl(value)
        ActionController::Base.helpers.number_to_currency(
          value,
          unit: "R$ ",
          separator: ",",
          delimiter: "."
        )
      end
    end
  end
end
