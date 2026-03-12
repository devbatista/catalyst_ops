class App::SupportController < ApplicationController
  skip_authorization_check
  
  def index
    @section = params[:section].presence || "overview"

    case @section
    when "tickets"
      load_tickets_section
    when "knowledge_base"
      # por enquanto pode ser só conteúdo estático na view
    when "suggestions"
      # mesma ideia: formulário simples na view, sem lógica extra ainda
    when "quick_contact"
      load_quick_contact_section
    else # "overview"
      load_overview_section
    end
  end

  private

  def load_tickets_section
    scope = current_user.company.support_tickets.recent
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(category: params[:category]) if params[:category].present?
  
    per_page = params[:per].presence || 10
    @support_tickets = scope.page(params[:page]).per(per_page)
  end

  def load_overview_section
    tickets = current_user.company.support_tickets
  
    @total_tickets        = tickets.count
    @open_tickets_count   = tickets.where(status: [:aberto, :em_andamento, :aguardando_cliente]).count
    @resolved_last_30_days = tickets.where(status: :resolvido)
                                    .where("updated_at >= ?", 30.days.ago)
                                    .count
    @last_open_ticket     = tickets.where(status: [:aberto, :em_andamento, :aguardando_cliente])
                                   .order(last_reply_at: :desc)
                                   .first
  end

  def load_quick_contact_section
    @can_use_quick_contact =
      current_user.company&.plan&.name.in?(["Profissional", "Enterprise"])
  end
end