constraints subdomain: "app" do
  root to: "app/dashboard#index", as: :app_dashboard
  get "order_services/new", to: "errors#show", defaults: { code: "404" }

  resource :terms_of_use, only: [:show, :update], controller: "app/terms_of_use", as: :app_terms_of_use

  resources :clients, module: "app", as: :app_clients
  resources :budgets, only: [:index, :new, :create, :show, :edit, :update], module: "app", as: :app_budgets do
    member do
      post :send_for_approval
      patch :approve
      patch :reject
      get :generate_pdf
    end
  end
  resources :order_services, except: [:new, :create], module: "app", as: :app_order_services do
    get :unassigned, on: :collection
    get :overdue, on: :collection
    resources :service_items, module: "order_services", as: :app_service_items
    member do
      patch :update_status
      get :generate_pdf
      delete :purge_attachment
      get :attachments
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
  resources :knowledge_base, only: [:index], module: "app", as: :app_knowledge_base
  resources :financial, only: [:index], module: "app", as: :app_financial
  resources :technicians, module: "app", as: :app_technicians
  resources :calendar, only: [:index], module: "app", as: :app_calendar
  resources :configurations, only: [:index], module: "app", as: :app_configurations do
    collection do
      patch :update_profile
      patch :update_company
      patch :upgrade_plan
      post :promote_manager
    end
  end

  get "calendar/events", to: "app/calendar#events"
  get "calendar/technicians", to: "app/calendar#technicians"

  resources :support, only: [:index], module: "app", as: :app_support do
    collection do
      post :suggestions
    end
  end

  resources :support_tickets, module: "app", as: :app_support_tickets, only: [:index, :show, :new, :create] do
    member do
      patch :close
    end
  end
  resources :support_messages, only: [:create], module: "app", as: :app_support_messages

  devise_scope :user do
    delete "/logout", to: "sessions#destroy", as: :logout_app
  end
end
