class Ability
  include CanCan::Ability

  def initialize(user)
    user = User.find_by(id: user["id"]) if user.is_a?(Hash) && user["id"]
    user ||= User.new

    case user.role
    when 'admin'
      admin_abilities
    when 'gestor'
      gestor_abilities(user)
    when 'tecnico'
      tecnico_abilities(user)
    else
      guest_abilities
    end
  end

  private

  def admin_abilities
    # Admin pode tudo
    can :manage, :all
  end

  def gestor_abilities(user)
    # NÃO pode gerenciar Company
    cannot :manage, Company

    # Pode gerenciar clientes
    can :manage, Client, company_id: user.company_id
    
    # Pode gerenciar ordens de serviço
    can :manage, OrderService
    
    # Pode gerenciar atribuições
    can :manage, Assignment
    
    # Pode gerenciar itens de serviço
    can :manage, ServiceItem
    
    # Pode visualizar técnicos
    can :read, User, role: 'tecnico'
    
    # Pode editar próprio perfil
    can [:read, :update], User, id: user.id

    # Dashboard
    can :read, :dashboard
  end

  def tecnico_abilities(user)
    # NÃO pode gerenciar Company
    cannot :manage, Company
    
    # Pode visualizar apenas OSs atribuídas a ele
    can :read, OrderService do |order_service|
      order_service.users.include?(user)
    end
    
    # Pode atualizar status das OSs atribuídas
    can :update, OrderService do |order_service|
      order_service.users.include?(user) && !order_service.concluida?
    end
    
    # Pode gerenciar itens de serviço das suas OSs
    can :manage, ServiceItem do |service_item|
      service_item.order_service.users.include?(user)
    end
    
    # Pode ver próprias atribuições
    can :read, Assignment, user_id: user.id
    
    # Pode editar próprio perfil
    can [:read, :update], User, id: user.id
    
    # Pode visualizar clientes das suas OSs
    can :read, Client do |client|
      client.order_services.joins(:users).where(users: { id: user.id }).any?
    end

    can :read, :dashboard
  end

  def guest_abilities
    # Usuários não logados não podem fazer nada
  end
end