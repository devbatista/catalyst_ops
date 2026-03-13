class Admin::SupportMessagesController < AdminController
  def create
    @support_message = SupportMessage.new(support_message_params)
    @support_message.user = current_user

    if @support_message.save
      redirect_to admin_ticket_path(@support_message.support_ticket),
                  notice: "Mensagem enviada com sucesso."
    else
      @ticket = @support_message.support_ticket
      @support_messages = @ticket.support_messages.order(:created_at)

      flash.now[:alert] = "Não foi possível enviar a mensagem."
      render "admin/tickets/show", status: :unprocessable_entity
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