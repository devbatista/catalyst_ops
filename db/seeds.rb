if Rails.env.production?
  forced_by_flag = ARGV.include?("--force")
  forced_by_env = ENV["SEED_FORCE"] == "1"

  unless forced_by_flag || forced_by_env
    abort <<~MSG
      [db:seed] Execucao bloqueada em producao.
      Operacao requer confirmacao explicita.
    MSG
  end
end

Dir[Rails.root.join('db/seeds/common/*.rb')].sort.each { |file| load file }

env_dir = Rails.root.join('db', 'seeds', Rails.env)
if Dir.exist?(env_dir)
  Dir[env_dir.join('*.rb')].sort.each { |file| load file }
end
