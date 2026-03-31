constraints subdomain: "cliente" do
  scope module: :cliente do
    get "budget_approvals/:token", to: "budget_approvals#show", as: :budget_approval
    patch "budget_approvals/:token/approve", to: "budget_approvals#approve", as: :approve_budget_approval
    patch "budget_approvals/:token/reject", to: "budget_approvals#reject", as: :reject_budget_approval
  end
end
