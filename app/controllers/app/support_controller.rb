class App::SupportController < ApplicationController
  skip_authorization_check
  
  def index
    @section = params[:section].presence || "overview"

    case @section
    when "tickets"
      load_tickets_section
    when "knowledge_base"
      @articles = KnowledgeBaseArticle.for_audience(current_user.role).order(:category, :title)
    when "suggestions"
      build_suggestion_form
    when "quick_contact"
      load_quick_contact_section
    else # "overview"
      load_overview_section
    end
  end

  def suggestions
    @section = "suggestions"
    @suggestion_form = suggestion_params.to_h.symbolize_keys

    if invalid_suggestion_form?
      flash.now[:alert] = "Preencha título, tipo, impacto e descrição da sugestão."
      return render :index, status: :unprocessable_entity
    end

    SuggestionsMailer.submit_suggestion(
      user: current_user,
      company: current_user.company,
      suggestion: @suggestion_form,
    ).deliver_later

    redirect_to app_support_index_path(section: "suggestions"),
                notice: "Sugestão enviada com sucesso."
  end

  private

  def build_suggestion_form
    @suggestion_form = {
      title: "",
      suggestion_type: "produto",
      impact: "ajuda_bastante",
      description: "",
    }
  end

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

  def suggestion_params
    params.require(:suggestion).permit(:title, :suggestion_type, :impact, :description)
  end

  def invalid_suggestion_form?
    @suggestion_form.values_at(:title, :suggestion_type, :impact, :description).any?(&:blank?)
  end
end
