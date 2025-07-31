constraints subdomain: "login" do
  devise_scope :user do
    get "/", to: "sessions#new", as: :login_root
    post "/login", to: "sessions#create", as: :login
    delete "/logout", to: "sessions#destroy", as: :logout
    
    get "/new_password", to: "sessions#new_password", as: :new_password
  end
end
