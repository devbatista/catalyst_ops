constraints subdomain: 'login' do
  get  '/',      to: 'sessions#new',     as: :login_root
  post '/login', to: 'sessions#create',  as: :login
  delete '/logout', to: 'sessions#destroy',  as: :logout
end