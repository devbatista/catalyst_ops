constraints subdomain: "mobile" do
  scope module: "mobile/v1", path: "v1", defaults: { format: :json } do
    get "health", to: "health#show"

    post "auth/login", to: "auth#login"
    get "auth/me", to: "auth#me"
    delete "auth/logout", to: "auth#logout"
    delete "auth/logout_all", to: "auth#logout_all"

    get "users/me", to: "users#me"

    get "mobile/dashboard", to: "dashboard#show"
    get "mobile/agenda", to: "agenda#index"
    resources :service_orders, controller: "order_services", path: "mobile/service_orders", only: [:index, :show, :update]

    resources :order_services, only: [:index, :show, :update]
    resources :budgets, only: [:index, :show]
  end
end
