User.find_or_create_by!(email: 'rafael@devbatista.com') do |user|
  user.name = 'Rafael Batista'
  user.password = 'senha123'
  user.password_confirmation = 'senha123'
  user.role = :admin
  user.active = true
end