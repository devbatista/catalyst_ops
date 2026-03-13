class Admin::SupportMessagesController < AdminController
  def create
    ticket = SupportTicket.find(support_message_params[:support_ticket_id])

    attachments = support_message_params[:attachments]

    @support_message = ticket.add_message!(
      user: current_user,
      body: support_message_params[:body],
      attachments: attachments
    )

    redirect_to admin_ticket_path(ticket),
                notice: "Mensagem enviada com sucesso."
  rescue ActiveRecord::RecordInvalid => e
    @support_message = e.record
    @ticket = @support_message.support_ticket
    @support_messages = @ticket.support_messages.order(:created_at)

    flash.now[:alert] = @support_message.errors.full_messages.to_sentence
    render "admin/tickets/show", status: :unprocessable_entity
  end

  private

  def support_message_params
    params.require(:support_message).permit(
      :support_ticket_id,
      :body,
      attachments: []
    )
  end
end