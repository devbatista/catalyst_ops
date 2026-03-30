constraints subdomain: "cliente" do
  scope module: :cliente do
    get "order_service_approvals/:token", to: "order_service_approvals#show", as: :order_service_approval
    patch "order_service_approvals/:token/approve", to: "order_service_approvals#approve", as: :approve_order_service_approval
    patch "order_service_approvals/:token/reject", to: "order_service_approvals#reject", as: :reject_order_service_approval
  end
end
