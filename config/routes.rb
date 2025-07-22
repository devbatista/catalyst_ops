Rails.application.routes.draw do
  instance_eval(File.read(Rails.root.join("config/routes/admin.rb")))
  instance_eval(File.read(Rails.root.join("config/routes/app.rb")))
  instance_eval(File.read(Rails.root.join("config/routes/login.rb")))

  # Rotas padrão (sem subdomínio)
  root to: 'home#index'
end