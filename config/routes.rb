def draw(routes_name)
  instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
end

Rails.application.routes.draw do
  %w[404 422 500 503].each do |code|
    match code, to: "errors#show", via: :all, code: code
  end

  match "errors/:code",
        to: "errors#show",
        via: :all,
        constraints: { code: /404|422|500|503/ }

  devise_for :users, skip: [:sessions]

  draw :admin
  draw :app
  draw :login
  draw :register
  draw :cliente
  draw :webhook
  draw :mobile

  # Rotas padrão (sem subdomínio)
  # root to: "home#index"
  match '/', to: proc { [204, {}, []] }, via: :options

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
