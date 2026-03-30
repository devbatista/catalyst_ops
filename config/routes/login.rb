constraints subdomain: "login" do
  devise_scope :user do
    get "/", to: "sessions#new", as: :login_root
    post "/login", to: "sessions#create", as: :login
    delete "/logout", to: "sessions#destroy", as: :logout

    get "/forgot_password", to: "sessions#forgot_password", as: :forgot_password
    post "/forgot_password", to: "sessions#send_reset_password", as: :send_reset_password

    get "/new_password", to: "sessions#new_password", as: :new_password
    put "/new_password", to: "sessions#update_password", as: :update_password
    get "/confirm_signup", to: "sessions#confirm_signup", as: :confirm_signup
  end
end
