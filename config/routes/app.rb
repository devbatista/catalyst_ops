constraints subdomain: "app" do
  root to: "app/dashboard#index", as: :app_dashboard

  resources :clients, module: "app", as: :app_clients
  resources :order_services, module: "app", as: :app_order_services do
    get :unassigned, on: :collection
    get :overdue, on: :collection
    resources :service_items, module: "order_services", as: :app_service_items
    member do
      patch :update_status
      get :generate_pdf
      delete :purge_attachment
      get :schedule
      patch :perform_schedule
    end
  end
  resources :attachments, only: [:index, :show, :destroy], module: "app", as: :app_attachments
  resources :reports, only: [:index, :show], module: "app", as: :app_reports do
    collection do
      get :service_orders
      post :service_orders
    end
  end
  resources :technicians, module: "app", as: :app_technicians
  resources :calendar, only: [:index], module: "app", as: :app_calendar
  resources :configurations, only: [:index], module: "app", as: :app_configurations do
    collection do
      patch :update_profile
      patch :update_company
      post :promote_manager
    end
  end

  get "calendar/events", to: "app/calendar#events"

  resources :support, only: [:index], module: "app", as: :app_support

  devise_scope :user do
    delete "/logout", to: "sessions#destroy", as: :logout_app
  end
end
