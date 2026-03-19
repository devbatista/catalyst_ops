class App::SupportMessagesController < ApplicationController
  skip_authorization_check

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

    redirect_to app_support_ticket_path(@support_ticket),
                notice: "Mensagem enviada com sucesso."
  rescue ActiveRecord::RecordInvalid => e
    @support_message = e.record
    @support_messages = @support_ticket.support_messages.order(created_at: :asc)

    flash.now[:alert] = @support_message.errors.full_messages.to_sentence
    render "app/support_tickets/show", status: :unprocessable_entity
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
