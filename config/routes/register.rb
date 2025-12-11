constraints subdomain: "register" do
  scope module: :register, path: "/" do
    root to: "signups#new"
    resources :signups, only: [:new, :create]
    get "/success", to: "signups#success"
  end
end