module ApplicationHelper
  def active_menu_class(path)
    current_page?(path) ? "active" : ""
  end

  def active_support_menu_class
    if controller_path.start_with?("app/support") || controller_path == "app/support_tickets" || controller_path == "app/knowledge_base"
      "active"
    else
      ""
    end
  end

  def active_support_tickets_menu_class
    if controller_path == "app/support" && params[:section] == "tickets"
      "active"
    elsif controller_path == "app/support_tickets"
      "active"
    else
      ""
    end
  end

  def currency_br(value)
    number_to_currency(
      value,
      unit: "R$ ",
      separator: ",",
      delimiter: ".",
    )
  end

  def custom_paginate(collection, window: 1)
    current_page = collection.current_page
    total_pages = collection.total_pages

    content_tag(:ul, class: "pagination mb-0") do
      pages = []

      pages << page_item("Previous", collection.prev_page, current_page, !collection.prev_page)
      pages << page_item(1, 1, current_page)
      pages << page_item("...", nil, current_page, true) if current_page > window + 1

      ((current_page - window)..(current_page + window)).each do |page|
        if page > 1 && page < total_pages
          pages << page_item(page, page, current_page)
        end
      end

      pages << page_item("...", nil, current_page, true) if current_page < total_pages - window - 1
      pages << page_item(total_pages, total_pages, current_page) if total_pages > 1
      pages << page_item("Next", collection.next_page, current_page, !collection.next_page)

      safe_join(pages)
    end
  end

  def ticket_status_badge(ticket)
    status_class =
      case ticket.status.to_sym
      when :aberto              then "secondary"
      when :em_andamento        then "info"
      when :aguardando_cliente  then "warning"
      when :resolvido           then "success"
      when :fechado, :cancelado then "dark"
      else "secondary"
      end

    content_tag :span, ticket.status.humanize, class: "badge bg-#{status_class}"
  end

  def ticket_impact_badge(ticket)
    impact_sym = ticket.impact&.to_sym

    impact_class =
      case impact_sym
      when :bloqueante then "danger"
      when :alto       then "warning"
      when :medio      then "info"
      else "secondary"
      end

    content_tag :span,
                (ticket.impact&.humanize || "-"),
                class: "badge bg-#{impact_class}"
  end

  def subscription_status_badge(subscription)
    status = subscription.status.to_s

    css_class, label =
      case status
      when "active"
        ["success",   "Ativa"]
      when "pending"
        ["warning text-dark", "Pendente"]
      when "cancelled"
        ["danger",    "Cancelada"]
      when "expired"
        ["secondary", "Expirada"]
      else
        ["secondary", status]
      end

    content_tag :span, label, class: "badge bg-#{css_class}"
  end

  private

  def page_item(label, page_number, current_page, is_disabled = false)
    is_active = page_number.present? && page_number == current_page

    li_classes = ["page-item"]
    li_classes << "active" if is_active
    li_classes << "disabled" if !is_active && (page_number.nil? || is_disabled)

    link = page_number ? link_to(label,
                                 url_for(params.permit(:code, :per).merge(page: page_number)),
                                 class: "page-link") : content_tag(:span, label, class: "page-link")

    content_tag(:li, link, class: li_classes.join(" "))
  end
end
