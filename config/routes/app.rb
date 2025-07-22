Rails.application.routes.draw do
  constraints subdomain: "app" do
    namespace :app do
      resources :order_services
      resources :clients
      match '/', to: 'dashboard#index', via: [:get, :options], as: :root
    end
  end
end
