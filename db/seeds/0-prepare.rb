puts 'Limpando dados antigos...'

ActiveRecord::Base.connection.execute("DELETE FROM service_items")
ActiveRecord::Base.connection.execute("DELETE FROM assignments")
ActiveRecord::Base.connection.execute("DELETE FROM order_services")
ActiveRecord::Base.connection.execute("DELETE FROM users")
ActiveRecord::Base.connection.execute("DELETE FROM clients")
ActiveRecord::Base.connection.execute("DELETE FROM companies")

puts 'Base limpa!'
puts '###################################'