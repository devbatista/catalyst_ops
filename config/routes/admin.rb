Rails.application.routes.draw do
  constraints subdomain: "admin" do
    namespace :admin do
      resources :companies
      match '/', to: 'companies#index', via: [:get, :options], as: :root
    end
  end
end
