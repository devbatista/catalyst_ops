Rails.application.routes.draw do
  devise_for :users
  root "dashboard#index"
  
  resources :clients
  resources :order_services do
    resources :service_items, except: [:index, :show]
    member do
      put :assign_technician
      put :update_status
    end
  end
  
  resources :users, only: [:index, :show, :edit, :update]

  get "up" => "rails/health#show", as: :rails_health_check
end
