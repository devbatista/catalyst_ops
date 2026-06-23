class App::SupportMessagesController < ApplicationController
  skip_authorization_check
  before_action :ensure_ticket_support_available

  def create
    @support_ticket = current_user.company.support_tickets.find(
      support_message_params[:support_ticket_id]
    )

    attachments = support_message_params[:attachments]

    @support_message = @support_ticket.add_message!(
      user: current_user,
      body: support_message_params[:body],
      attachments: attachments
    )
    SupportTicketNotifications.notify_message(message: @support_message, actor: current_user)

    redirect_to app_support_ticket_path(@support_ticket),
                notice: "Mensagem enviada com sucesso."
  rescue ActiveRecord::RecordInvalid => e
    @support_message = e.record
    @support_messages = @support_ticket.support_messages.order(created_at: :asc)

    flash.now[:alert] = @support_message.errors.full_messages.to_sentence
    render "app/support_tickets/show", status: :unprocessable_entity
  end

  private

  def ensure_ticket_support_available
    return unless current_user.company&.starter_plan?

    redirect_to app_support_index_path(section: "knowledge_base"),
                alert: "O plano Starter oferece suporte somente via base de conhecimento."
  end

  def support_message_params
    params.require(:support_message).permit(
      :support_ticket_id,
      :body,
      attachments: []
    )
  end
end
