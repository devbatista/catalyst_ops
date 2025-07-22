Rails.application.routes.draw do
  constraints subdomain: 'app' do
    resources :order_services
    resources :clients
    # Outras rotas do app...
    root to: 'dashboard#index', as: :app_root
  end
end