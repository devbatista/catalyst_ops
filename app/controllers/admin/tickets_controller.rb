class Admin::TicketsController < AdminController
  def index
    @tickets = SupportTicket.includes(:company, :user).recent
  
    @tickets = @tickets.where(status: params[:status]) if params[:status].present?
    @tickets = @tickets.where(category: params[:category]) if params[:category].present?
  
    if params[:q].present?
      q = "%#{params[:q]}%"
      @tickets = @tickets.joins(:company, :user).where(
        "support_tickets.subject ILIKE :q OR support_tickets.description ILIKE :q OR companies.name ILIKE :q OR users.name ILIKE :q",
        q: q
      )
    end
  
    per_page = (params[:per].presence || 10).to_i
    @tickets = @tickets.page(params[:page]).per(per_page)
  end

  def show
    @ticket = SupportTicket
      .includes(:company, :user, :order_service, support_messages: :user)
      .find(params[:id])

    @support_messages = @ticket.support_messages.order(:created_at)
  end

  def resolve
    @ticket = SupportTicket.find(params[:id])

    if @ticket.update(status: :resolvido)
      redirect_to admin_ticket_path(@ticket), notice: "Ticket marcado como resolvido."
    else
      redirect_to admin_ticket_path(@ticket),
                  alert: @ticket.errors.full_messages.to_sentence
    end
  end
end