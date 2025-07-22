Rails.application.routes.draw do
  constraints subdomain: 'admin' do
    resources :companies
    # Outras rotas de admin...
    root to: 'admin/dashboard#index', as: :admin_root
  end
end