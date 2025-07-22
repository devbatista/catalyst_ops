Rails.application.routes.draw do
  devise_for :users, skip: [:sessions]
  
  instance_eval(File.read(Rails.root.join("config/routes/admin.rb")))
  instance_eval(File.read(Rails.root.join("config/routes/app.rb")))
  instance_eval(File.read(Rails.root.join("config/routes/login.rb")))

  # Rotas padrão (sem subdomínio)
  match '/', to: 'home#index', via: [:get, :options]
end