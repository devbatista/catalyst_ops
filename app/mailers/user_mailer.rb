class UserMailer < ApplicationMailer
  def welcome_email(user, token)
    @user = user
    @reset_password_url = new_password_url(reset_password_token: token)
    mail(to: @user.email, subject: "Sua conta no CatalystOps foi criada!")
  end
end
