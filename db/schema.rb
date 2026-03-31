# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_03_31_190000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.string "street"
    t.string "number"
    t.string "complement"
    t.string "neighborhood"
    t.string "zip_code"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "address_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["client_id"], name: "index_addresses_on_client_id"
    t.index ["deleted_at"], name: "index_addresses_on_deleted_at"
  end

  create_table "assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "order_service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_service_id"], name: "index_assignments_on_order_service_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "audit_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "occurred_at", null: false
    t.string "action", null: false
    t.string "source"
    t.string "actor_type"
    t.string "actor_id"
    t.uuid "company_id"
    t.string "resource_type"
    t.string "resource_id"
    t.string "request_id"
    t.string "ip_address"
    t.text "user_agent"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_events_on_action"
    t.index ["actor_type", "actor_id", "occurred_at"], name: "idx_audit_events_actor_occurred_at"
    t.index ["company_id", "occurred_at"], name: "idx_audit_events_company_occurred_at"
    t.index ["company_id"], name: "index_audit_events_on_company_id"
    t.index ["occurred_at"], name: "index_audit_events_on_occurred_at"
    t.index ["request_id"], name: "index_audit_events_on_request_id"
    t.index ["resource_type", "resource_id", "occurred_at"], name: "idx_audit_events_resource_occurred_at"
  end

  create_table "budgets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "client_id", null: false
    t.uuid "order_service_id"
    t.integer "code", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.decimal "total_value", precision: 12, scale: 2, default: "0.0", null: false
    t.date "valid_until"
    t.datetime "approval_sent_at"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_budgets_on_client_id"
    t.index ["company_id", "code"], name: "index_budgets_on_company_id_and_code", unique: true
    t.index ["company_id", "status"], name: "index_budgets_on_company_id_and_status"
    t.index ["company_id"], name: "index_budgets_on_company_id"
    t.index ["created_at"], name: "index_budgets_on_created_at"
    t.index ["order_service_id"], name: "index_budgets_on_order_service_id"
  end

  create_table "clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "document"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "company_id", null: false
    t.datetime "deleted_at"
    t.index ["company_id"], name: "index_clients_on_company_id"
    t.index ["deleted_at"], name: "index_clients_on_deleted_at"
    t.index ["document"], name: "index_clients_on_document"
    t.index ["email"], name: "index_clients_on_email"
    t.index ["name"], name: "index_clients_on_name"
    t.index ["phone"], name: "index_clients_on_phone"
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "document", null: false
    t.string "email", null: false
    t.string "phone", null: false
    t.uuid "responsible_id"
    t.string "state_registration"
    t.string "municipal_registration"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "plan_id"
    t.string "payment_method", default: "boleto", null: false
    t.string "zip_code"
    t.string "street"
    t.string "number"
    t.string "complement"
    t.string "neighborhood"
    t.string "city"
    t.string "state"
    t.boolean "active", default: false, null: false
    t.string "terms_version_accepted"
    t.datetime "terms_accepted_at"
    t.string "terms_accepted_ip"
    t.text "terms_accepted_user_agent"
    t.uuid "terms_accepted_by_user_id"
    t.index ["active"], name: "index_companies_on_active"
    t.index ["city", "state"], name: "index_companies_on_city_and_state"
    t.index ["document"], name: "index_companies_on_document", unique: true
    t.index ["email"], name: "index_companies_on_email", unique: true
    t.index ["payment_method"], name: "index_companies_on_payment_method"
    t.index ["plan_id"], name: "index_companies_on_plan_id"
    t.index ["responsible_id"], name: "index_companies_on_responsible_id"
    t.index ["terms_accepted_by_user_id"], name: "index_companies_on_terms_accepted_by_user_id"
    t.index ["terms_version_accepted"], name: "index_companies_on_terms_version_accepted"
    t.index ["zip_code"], name: "index_companies_on_zip_code"
  end

  create_table "coupon_redemptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "coupon_id", null: false
    t.uuid "company_id", null: false
    t.uuid "subscription_id", null: false
    t.decimal "original_amount", precision: 10, scale: 2, null: false
    t.decimal "discount_amount", precision: 10, scale: 2, null: false
    t.decimal "final_amount", precision: 10, scale: 2, null: false
    t.datetime "applied_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["applied_at"], name: "index_coupon_redemptions_on_applied_at"
    t.index ["company_id", "applied_at"], name: "index_coupon_redemptions_on_company_id_and_applied_at"
    t.index ["company_id"], name: "index_coupon_redemptions_on_company_id"
    t.index ["coupon_id"], name: "index_coupon_redemptions_on_coupon_id"
    t.index ["subscription_id"], name: "index_coupon_redemptions_on_subscription_id", unique: true
  end

  create_table "coupons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.string "benefit_type", default: "discount", null: false
    t.string "discount_type"
    t.decimal "discount_value", precision: 10, scale: 2
    t.integer "max_redemptions"
    t.integer "redemptions_count", default: 0, null: false
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.boolean "first_cycle_only", default: true, null: false
    t.integer "trial_frequency"
    t.string "trial_frequency_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_coupons_on_active"
    t.index ["benefit_type"], name: "index_coupons_on_benefit_type"
    t.index ["code"], name: "index_coupons_on_code", unique: true
    t.index ["valid_until"], name: "index_coupons_on_valid_until"
  end

  create_table "knowledge_base_articles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "category"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "audience", default: "gestor", null: false
    t.index ["audience"], name: "index_knowledge_base_articles_on_audience"
    t.index ["slug"], name: "index_knowledge_base_articles_on_slug", unique: true
  end

  create_table "order_services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.uuid "client_id", null: false
    t.integer "status"
    t.datetime "scheduled_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.boolean "signed_by_client"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "company_id", null: false
    t.text "observations"
    t.integer "code"
    t.datetime "expected_end_at"
    t.datetime "approval_sent_at"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.text "rejection_reason"
    t.index ["client_id"], name: "index_order_services_on_client_id"
    t.index ["company_id", "code"], name: "index_order_services_on_company_id_and_code", unique: true
    t.index ["company_id", "status", "created_at"], name: "index_order_services_on_company_status_created_at"
    t.index ["company_id"], name: "index_order_services_on_company_id"
  end

  create_table "plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "reason", null: false
    t.string "status", default: "active", null: false
    t.string "external_id", null: false
    t.string "external_reference", null: false
    t.integer "frequency", null: false
    t.string "frequency_type", default: "months", null: false
    t.decimal "transaction_amount", precision: 10, scale: 2, null: false
    t.string "init_point"
    t.string "back_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_technicians"
    t.integer "max_orders"
    t.string "support_level"
    t.index ["external_id"], name: "index_plans_on_external_id", unique: true
    t.index ["external_reference"], name: "index_plans_on_external_reference", unique: true
    t.index ["status"], name: "index_plans_on_status"
  end

  create_table "reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.string "report_type", null: false
    t.uuid "user_id", null: false
    t.uuid "company_id", null: false
    t.datetime "generated_at"
    t.string "status", default: "pending"
    t.text "filters"
    t.string "file"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "generated_at"], name: "index_reports_on_company_id_and_generated_at"
    t.index ["company_id", "report_type"], name: "index_reports_on_company_id_and_report_type"
    t.index ["company_id", "status"], name: "index_reports_on_company_id_and_status"
    t.index ["company_id"], name: "index_reports_on_company_id"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "service_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "description"
    t.integer "quantity"
    t.decimal "unit_price"
    t.uuid "order_service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_service_id"], name: "index_service_items_on_order_service_id"
  end

  create_table "subscription_reconciliation_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_id", null: false
    t.uuid "company_id", null: false
    t.string "source_job", null: false
    t.integer "window_days"
    t.string "payment_method", null: false
    t.string "gateway_identifier", null: false
    t.string "gateway_status"
    t.string "local_status_before"
    t.string "local_status_after"
    t.boolean "divergent", default: false, null: false
    t.boolean "resolved", default: false, null: false
    t.string "result_status", default: "success", null: false
    t.text "error_message"
    t.jsonb "raw_payload", default: {}, null: false
    t.datetime "processed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_subscription_reconciliation_events_on_company_id"
    t.index ["divergent", "resolved"], name: "idx_reconciliation_events_divergent_resolved"
    t.index ["processed_at"], name: "index_subscription_reconciliation_events_on_processed_at"
    t.index ["result_status"], name: "index_subscription_reconciliation_events_on_result_status"
    t.index ["source_job", "processed_at"], name: "idx_reconciliation_events_source_processed_at"
    t.index ["subscription_id"], name: "index_subscription_reconciliation_events_on_subscription_id"
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "preapproval_plan_id", null: false
    t.string "reason"
    t.string "external_reference"
    t.date "start_date"
    t.date "end_date"
    t.datetime "canceled_date"
    t.decimal "transaction_amount", precision: 12, scale: 2
    t.string "status", default: "pending", null: false
    t.string "gateway", default: "mercado_pago"
    t.string "external_subscription_id"
    t.jsonb "raw_payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "expired_date"
    t.datetime "expiration_warning_sent_at"
    t.string "external_payment_id"
    t.index ["company_id", "status"], name: "index_subscriptions_on_company_id_and_status"
    t.index ["company_id"], name: "index_subscriptions_on_company_id"
    t.index ["expiration_warning_sent_at"], name: "index_subscriptions_on_expiration_warning_sent_at"
    t.index ["external_payment_id"], name: "index_subscriptions_on_external_payment_id"
    t.index ["external_reference"], name: "index_subscriptions_on_external_reference"
    t.index ["external_subscription_id"], name: "index_subscriptions_on_external_subscription_id"
    t.index ["preapproval_plan_id"], name: "index_subscriptions_on_preapproval_plan_id"
  end

  create_table "support_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "support_ticket_id", null: false
    t.uuid "user_id", null: false
    t.text "body", null: false
    t.boolean "internal", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["support_ticket_id", "created_at"], name: "index_support_messages_on_support_ticket_id_and_created_at"
    t.index ["support_ticket_id"], name: "index_support_messages_on_support_ticket_id"
    t.index ["user_id"], name: "index_support_messages_on_user_id"
  end

  create_table "support_tickets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "user_id", null: false
    t.uuid "order_service_id"
    t.string "subject", null: false
    t.text "description", null: false
    t.integer "category", default: 0, null: false
    t.integer "impact", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.integer "priority", default: 1, null: false
    t.uuid "assigned_to_id"
    t.datetime "last_reply_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_support_tickets_on_assigned_to_id"
    t.index ["company_id", "created_at"], name: "index_support_tickets_on_company_id_and_created_at"
    t.index ["company_id", "priority"], name: "index_support_tickets_on_company_id_and_priority"
    t.index ["company_id", "status"], name: "index_support_tickets_on_company_id_and_status"
    t.index ["company_id"], name: "index_support_tickets_on_company_id"
    t.index ["order_service_id"], name: "index_support_tickets_on_order_service_id"
    t.index ["user_id"], name: "index_support_tickets_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "role"
    t.uuid "company_id"
    t.string "phone"
    t.boolean "active", default: false, null: false
    t.boolean "can_be_technician", default: false
    t.datetime "welcome_email_sent_at"
    t.index ["active"], name: "index_users_on_active"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name", "email"], name: "index_users_on_name_and_email"
    t.index ["name"], name: "index_users_on_name"
    t.index ["phone"], name: "index_users_on_phone"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "webhook_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "provider", null: false
    t.string "event_key", null: false
    t.string "resource_id"
    t.string "event_type"
    t.string "status", default: "received", null: false
    t.datetime "processed_at"
    t.text "error_message"
    t.jsonb "payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "event_key"], name: "index_webhook_events_on_provider_and_event_key", unique: true
    t.index ["provider", "resource_id"], name: "index_webhook_events_on_provider_and_resource_id"
    t.index ["status"], name: "index_webhook_events_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "clients", on_delete: :cascade
  add_foreign_key "assignments", "order_services"
  add_foreign_key "assignments", "users"
  add_foreign_key "audit_events", "companies"
  add_foreign_key "budgets", "clients"
  add_foreign_key "budgets", "companies"
  add_foreign_key "budgets", "order_services"
  add_foreign_key "clients", "companies"
  add_foreign_key "companies", "plans"
  add_foreign_key "companies", "users", column: "responsible_id"
  add_foreign_key "companies", "users", column: "terms_accepted_by_user_id"
  add_foreign_key "coupon_redemptions", "companies"
  add_foreign_key "coupon_redemptions", "coupons"
  add_foreign_key "coupon_redemptions", "subscriptions"
  add_foreign_key "order_services", "clients"
  add_foreign_key "order_services", "companies"
  add_foreign_key "reports", "companies"
  add_foreign_key "reports", "users"
  add_foreign_key "service_items", "order_services"
  add_foreign_key "subscription_reconciliation_events", "companies"
  add_foreign_key "subscription_reconciliation_events", "subscriptions"
  add_foreign_key "subscriptions", "companies"
  add_foreign_key "support_messages", "support_tickets"
  add_foreign_key "support_messages", "users"
  add_foreign_key "support_tickets", "companies"
  add_foreign_key "support_tickets", "order_services"
  add_foreign_key "support_tickets", "users"
  add_foreign_key "support_tickets", "users", column: "assigned_to_id"
  add_foreign_key "users", "companies"
end
