constraints subdomain: "admin" do
  get "/", to: "admin/companies#index", as: :admin_dashboard

  namespace :admin do
    resources :companies
  end

  devise_scope :user do
    delete "/logout", to: "sessions#destroy", as: :logout_admin
  end
end
