constraints subdomain: "app" do
  get "/", to: "app/dashboard#index", as: :app_dashboard

  namespace :app do
    resources :order_services
    resources :clients
    root to: "dashboard#index"
  end

  devise_scope :user do
    delete "/logout", to: "sessions#destroy", as: :logout_app
  end
end
