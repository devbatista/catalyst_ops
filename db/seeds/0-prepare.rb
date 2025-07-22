puts 'Limpando dados antigos...'

ServiceItem.delete_all
Assignment.delete_all
OrderService.delete_all
Client.delete_all
User.delete_all
Company.delete_all

puts 'Base limpa!'
puts '###################################'