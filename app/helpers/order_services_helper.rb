module OrderServicesHelper
  def budget_status_label(order_service)
    case order_service.status.to_s
    when "rascunho"
      "pendente"
    when "rejeitada"
      "rejeitado"
    else
      order_service.status.humanize
    end
  end
end
