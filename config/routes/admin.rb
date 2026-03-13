constraints subdomain: "admin" do
  get "/", to: "admin/dashboard#index", as: :admin_dashboard

  resources :companies, module: "admin", as: :admin_companies
  resources :users, module: "admin", as: :admin_users
  resources :subscriptions, module: "admin", as: :admin_subscriptions
  resources :plans, module: "admin", as: :admin_plans
  resources :order_services, module: "admin", as: :admin_order_services do
    member do
      get :generate_pdf
    end
  end
  resources :tickets, only: [:index, :show], module: "admin", as: :admin_tickets
  resources :support_messages, only: [:create], module: "admin", as: :admin_support_messages
  resources :configurations, only: [:index, :edit, :update], module: "admin", as: :admin_configurations
  resources :contents, module: "admin", as: :admin_contents
  
  devise_scope :user do
    delete "/logout", to: "sessions#destroy", as: :logout_admin
  end
end
