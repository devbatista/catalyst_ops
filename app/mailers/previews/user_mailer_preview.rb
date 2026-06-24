module Previews
  class UserMailerPreview < ActionMailer::Preview
    def welcome_email
      user = User.first || User.new(name: "Example User", email: "test@user.com")
      token = "exemplo-token-reset"
      UserMailer.welcome_email(user, token)
    end

    def starter_welcome_email
      user = User.first || User.new(name: "Example User", email: "test@user.com")
      UserMailer.starter_welcome_email(user)
    end

    def signup_welcome_email
      user = User.first || User.new(name: "Example User", email: "test@user.com")
      UserMailer.signup_welcome_email(user)
    end
  end
end
