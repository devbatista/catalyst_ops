puts 'Limpando dados antigos...'
Company.update_all(responsible_id: nil)

ServiceItem.delete_all
Assignment.delete_all
OrderService.delete_all
Address.delete_all
Client.delete_all
User.delete_all
Company.delete_all
Subscription.delete_all
Plan.delete_all

puts 'Base limpa!'
puts '###################################'