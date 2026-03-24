class CreateCouponsAndCouponRedemptions < ActiveRecord::Migration[7.1]
  def change
    create_table :coupons, id: :uuid do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.string :benefit_type, null: false, default: "discount"
      t.string :discount_type
      t.decimal :discount_value, precision: 10, scale: 2
      t.integer :max_redemptions
      t.integer :redemptions_count, null: false, default: 0
      t.datetime :valid_from
      t.datetime :valid_until
      t.boolean :first_cycle_only, null: false, default: true
      t.integer :trial_frequency
      t.string :trial_frequency_type
      t.timestamps
    end

    add_index :coupons, :active
    add_index :coupons, :benefit_type
    add_index :coupons, :code, unique: true
    add_index :coupons, :valid_until

    create_table :coupon_redemptions, id: :uuid do |t|
      t.references :coupon, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :subscription, null: false, foreign_key: true, type: :uuid
      t.decimal :original_amount, precision: 10, scale: 2, null: false
      t.decimal :discount_amount, precision: 10, scale: 2, null: false
      t.decimal :final_amount, precision: 10, scale: 2, null: false
      t.datetime :applied_at, null: false
      t.timestamps
    end

    add_index :coupon_redemptions, :applied_at
    add_index :coupon_redemptions, [:company_id, :applied_at]
    add_index :coupon_redemptions, :subscription_id, unique: true
  end
end
