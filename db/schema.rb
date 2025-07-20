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

ActiveRecord::Schema[7.1].define(version: 2025_07_20_234725) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "order_service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_service_id"], name: "index_assignments_on_order_service_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "document"
    t.string "email"
    t.string "phone"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_services", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.bigint "client_id", null: false
    t.integer "status"
    t.datetime "scheduled_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.boolean "signed_by_client"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_order_services_on_client_id"
  end

  create_table "service_items", force: :cascade do |t|
    t.text "description"
    t.decimal "quantity"
    t.decimal "unit_price"
    t.bigint "order_service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_service_id"], name: "index_service_items_on_order_service_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "assignments", "order_services"
  add_foreign_key "assignments", "users"
  add_foreign_key "order_services", "clients"
  add_foreign_key "service_items", "order_services"
end
