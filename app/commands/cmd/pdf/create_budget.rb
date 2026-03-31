module Cmd
  module Pdf
    class CreateBudget
      def initialize(order_service)
        @order_service = order_service
        @company = @order_service.company
        @client = @order_service.client
      end

      def generate_pdf_data
        pdf = PdfGenerator.new
        header_bg = "21262E"
        border = "D9DDE3"
        soft_bg = "F3F5F7"
        muted = "6B7280"
        text = "111827"
        page_width = pdf.bounds.width

        # Header dark bar (with better paddings and inset)
        pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: page_width) do
          header_data = [[
            {
              content: "<b>Orçamento</b>\n<font size='2'> </font>\n<font size='10' color='C8CDD3'>Revise os dados antes de aprovar ou rejeitar.</font>",
              inline_format: true,
              background_color: header_bg,
              text_color: "FFFFFF",
              border_color: "1C2128",
              size: 16,
              padding: [12, 14, 12, 14],
              valign: :center
            },
            {
              content: "<b>OS ##{@order_service.code}</b>",
              inline_format: true,
              background_color: header_bg,
              text_color: "FFFFFF",
              border_color: "1C2128",
              align: :center,
              valign: :center,
              size: 11,
              padding: [12, 10, 12, 10]
            }
          ]]

          pdf.table(
            header_data,
            width: page_width,
            column_widths: [ page_width * 0.8, page_width * 0.2 ],
            cell_style: { borders: [:top, :bottom, :left, :right] }
          )
        end
        pdf.move_down(14)

        # Cards Cliente / Empresa
        cards = [[
          { content: "Cliente\n#{@client&.name}", background_color: soft_bg, border_color: border, size: 10, padding: [10, 12, 10, 12] },
          { content: "Empresa\n#{@company&.name}", background_color: soft_bg, border_color: border, size: 10, padding: [10, 12, 10, 12] }
        ]]
        pdf.table(cards, width: page_width, cell_style: { inline_format: true }, column_widths: [page_width / 2, page_width / 2])
        pdf.move_down(14)

        # Meta info
        info_data = [
          [ "Título", @order_service.title.to_s, "Código da OS", @order_service.code.to_s ],
          [ "Criada em", format_date(@order_service.created_at), "Documento", @client&.formatted_document.to_s ],
          [ "E-mail do cliente", @client&.email.to_s, "Telefone", @client&.formatted_phone.to_s ]
        ]

        pdf.table(
          info_data,
          width: page_width,
          cell_style: { size: 10, padding: [6, 8, 6, 8], border_color: border },
          column_widths: [page_width * 0.2, page_width * 0.3, page_width * 0.2, page_width * 0.3]
        )
        pdf.move_down(10)

        pdf.fill_color(text)
        pdf.font_size(11) { pdf.text("Descrição: #{@order_service.description}", style: :bold) }
        pdf.move_down(14)

        pdf.fill_color(muted)
        pdf.font_size(12) { pdf.text("ITENS DA ORDEM DE SERVIÇO", style: :bold) }
        pdf.fill_color(text)
        pdf.move_down(4)

        item_rows = [[ "Descrição", "Qtd.", "Valor unitário", "Total" ]]
        @order_service.service_items.order(:created_at).each do |item|
          item_rows << [
            item.description.to_s,
            item.quantity.to_s,
            brl(item.unit_price),
            brl(item.quantity.to_d * item.unit_price.to_d)
          ]
        end

        if item_rows.size == 1
          item_rows << [ "Sem itens cadastrados", "-", "-", "-" ]
        end

        pdf.table(
          item_rows,
          header: true,
          width: page_width,
          cell_style: { size: 10, padding: [6, 8, 6, 8], border_color: border, inline_format: true },
          row_colors: [ "FFFFFF", soft_bg ],
          column_widths: [page_width * 0.42, page_width * 0.12, page_width * 0.23, page_width * 0.23]
        )
        pdf.move_down(10)
        pdf.font_size(16) { pdf.text("Total: #{brl(@order_service.total_value)}", align: :right, style: :bold) }
        pdf.render
      end

      private

      def brl(value)
        ActionController::Base.helpers.number_to_currency(
          value,
          unit: "R$ ",
          separator: ",",
          delimiter: "."
        )
      end

      def format_date(value)
        return "-" if value.blank?

        I18n.l(value.to_date, format: "%d/%m/%Y")
      end
    end
  end
end
