def draw(routes_name)
  instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
end

Rails.application.routes.draw do
  devise_for :users, skip: [:sessions]

  draw :admin
  draw :app
  draw :login
  draw :register

  # Rotas padrão (sem subdomínio)
  # root to: "home#index"
  match '/', to: proc { [204, {}, []] }, via: :options

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end