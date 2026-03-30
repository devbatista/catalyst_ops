class AddApprovalFieldsToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_column :order_services, :approval_sent_at, :datetime
    add_column :order_services, :approved_at, :datetime
    add_column :order_services, :rejected_at, :datetime
    add_column :order_services, :rejection_reason, :text
  end
end
