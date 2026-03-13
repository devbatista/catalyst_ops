class App::SupportMessagesController < ApplicationController
  skip_authorization_check

  def create
    @support_ticket = current_user.company.support_tickets.find(support_message_params[:support_ticket_id])

    @support_message = @support_ticket.support_messages.build(
      body: support_message_params[:body],
      user: current_user
    )
    @support_message.attachments.attach(support_message_params[:attachments]) if support_message_params[:attachments]

    @support_messages = @support_ticket.support_messages.order(created_at: :asc)

    if @support_message.save
      redirect_to app_support_ticket_path(@support_ticket), notice: "Mensagem enviada com sucesso."
    else
      flash.now[:alert] = @support_message.errors.full_messages.to_sentence
      render "app/support_tickets/show", status: :unprocessable_entity
    end
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