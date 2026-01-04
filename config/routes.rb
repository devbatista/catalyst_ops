def draw(routes_name)
  instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
end

Rails.application.routes.draw do
  # --- CATCH-ALL PARA DEBUG (primeiro para garantir que pega antes dos constraints) ---
  match "/", to: proc { |env|
    [
      200,
      { "Content-Type" => "text/plain" },
      ["DEBUG: HOST=#{env['HTTP_HOST']} | PATH=#{env['PATH_INFO']}"]
    ]
  }, via: :all

  # devise_for :users, skip: [:sessions]

  # draw :admin
  # draw :app
  # draw :login
  # draw :register
  # draw :sidekiq

  # Rotas padrão (sem subdomínio)
  # root to: "home#index"
  # match '/', to: proc { [204, {}, []] }, via: :options

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # --- CATCH-ALL PARA OUTROS PATHS ---
  match "*path", to: proc { |env|
    [
      200,
      { "Content-Type" => "text/plain" },
      ["DEBUG: HOST=#{env['HTTP_HOST']} | PATH=#{env['PATH_INFO']}"]
    ]
  }, via: :all
end