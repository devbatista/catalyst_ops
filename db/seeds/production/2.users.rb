User.find_or_create_by!(email: 'admin@catalystops.com.br') do |user|
  user.name = 'Rafael Batista'
  user.password = 'ShowdeBola#10'
  user.password_confirmation = 'ShowdeBola#10'
  user.role = :admin
  user.active = true
end