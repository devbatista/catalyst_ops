class Admin::EmailsController < AdminController
  def show
    @email = params[:email].to_s
  end

  def create
    @email = email_param

    unless valid_email?(@email)
      flash.now[:alert] = "Informe um e-mail válido."
      render :show, status: :unprocessable_entity
      return
    end

    begin
      AdminMailer.test_email(@email, current_user).deliver_later
    rescue StandardError => e
      Rails.logger.error("[Admin::EmailsController] E-mail de teste não enviado para #{@email}: #{e.class} - #{e.message}")
      flash.now[:alert] = "Não foi possível enviar o e-mail de teste."
      render :show, status: :unprocessable_entity
      return
    end

    redirect_to admin_email_path, notice: "E-mail de teste enviado para #{@email}."
  end

  private

  def email_param
    params.dig(:email_test, :email).to_s.strip.downcase
  end

  def valid_email?(email)
    email.match?(URI::MailTo::EMAIL_REGEXP)
  end
end
