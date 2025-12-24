class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    user = User.first || User.new(name: "Example User", email: "test@user.com")
    token = "exemplo-token-reset"
    UserMailer.welcome_email(user, token)
  end
end