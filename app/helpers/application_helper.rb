module ApplicationHelper
  def active_menu_class(path)
    current_page?(path) ? "active" : ""
  end

  def currency_br(value)
    number_to_currency(
      value,
      unit: "R$ ",
      separator: ",",
      delimiter: "."
    )
  end
end
