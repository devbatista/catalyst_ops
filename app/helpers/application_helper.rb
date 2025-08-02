module ApplicationHelper
  def active_menu_class(path)
    current_page?(path) ? "active" : ""
  end
end
