class App::SupportTicketsController < ApplicationController
  skip_authorization_check

  def index
    scope = current_user.company.support_tickets.recent
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(category: params[:category]) if params[:category].present?

    per_page = params[:per].presence || 10
    @support_tickets = scope.page(params[:page]).per(per_page)
  end

  def show
    @support_ticket = current_user.company.support_tickets.find(params[:id])
    @support_messages = @support_ticket.support_messages.order(created_at: :asc)
  end

  def new
    @support_ticket = current_user.company.support_tickets.build(
      user: current_user,
      impact: :medio,
      priority: :normal
    )
  end

  def create
    @support_ticket = current_user.company.support_tickets.build(support_ticket_params)
    @support_ticket.user = current_user
    @support_ticket.status ||= :aberto

    if @support_ticket.save
      redirect_to app_support_ticket_path(@support_ticket),
                  notice: "Ticket criado com sucesso."
    else
      flash.now[:alert] = @support_ticket.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def support_ticket_params
    params.require(:support_ticket).permit(
      :subject,
      :description,
      :category,
      :impact,
      :priority,
      :order_service_id,
      attachments: []
    )
  end
end