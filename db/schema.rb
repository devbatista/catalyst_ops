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

ActiveRecord::Schema[7.1].define(version: 2025_12_10_141645) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

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

  create_table "annotation_tag_entity", id: { type: :string, limit: 16 }, force: :cascade do |t|
    t.string "name", limit: 24, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.index ["name"], name: "IDX_ae51b54c4bb430cf92f48b623f", unique: true
  end

  create_table "assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "order_service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_service_id"], name: "index_assignments_on_order_service_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "auth_identity", primary_key: ["providerId", "providerType"], force: :cascade do |t|
    t.uuid "userId"
    t.string "providerId", limit: 64, null: false
    t.string "providerType", limit: 32, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
  end

  create_table "auth_provider_sync_history", id: :serial, force: :cascade do |t|
    t.string "providerType", limit: 32, null: false
    t.text "runMode", null: false
    t.text "status", null: false
    t.timestamptz "startedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamptz "endedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "scanned", null: false
    t.integer "created", null: false
    t.integer "updated", null: false
    t.integer "disabled", null: false
    t.text "error"
  end

  create_table "binary_data", primary_key: "fileId", id: :uuid, default: nil, force: :cascade do |t|
    t.string "sourceType", limit: 50, null: false, comment: "Source the file belongs to, e.g. 'execution'"
    t.string "sourceId", limit: 255, null: false, comment: "ID of the source, e.g. execution ID"
    t.binary "data", null: false, comment: "Raw, not base64 encoded"
    t.string "mimeType", limit: 255
    t.string "fileName", limit: 255
    t.integer "fileSize", null: false, comment: "In bytes"
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.index ["sourceType", "sourceId"], name: "IDX_56900edc3cfd16612e2ef2c6a8"
    t.check_constraint "\"sourceType\"::text = ANY (ARRAY['execution'::character varying, 'chat_message_attachment'::character varying]::text[])", name: "CHK_binary_data_sourceType"
  end

  create_table "chat_hub_agents", id: :uuid, default: nil, force: :cascade do |t|
    t.string "name", limit: 256, null: false
    t.string "description", limit: 512
    t.text "systemPrompt", null: false
    t.uuid "ownerId", null: false
    t.string "credentialId", limit: 36
    t.string "provider", limit: 16, null: false, comment: "ChatHubProvider enum: \"openai\", \"anthropic\", \"google\", \"n8n\""
    t.string "model", limit: 64, null: false, comment: "Model name used at the respective Model node, ie. \"gpt-4\""
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.json "tools", default: [], null: false, comment: "Tools available to the agent as JSON node definitions"
  end

  create_table "chat_hub_messages", id: :uuid, default: nil, force: :cascade do |t|
    t.uuid "sessionId", null: false
    t.uuid "previousMessageId"
    t.uuid "revisionOfMessageId"
    t.uuid "retryOfMessageId"
    t.string "type", limit: 16, null: false, comment: "ChatHubMessageType enum: \"human\", \"ai\", \"system\", \"tool\", \"generic\""
    t.string "name", limit: 128, null: false
    t.text "content", null: false
    t.string "provider", limit: 16, comment: "ChatHubProvider enum: \"openai\", \"anthropic\", \"google\", \"n8n\""
    t.string "model", limit: 64, comment: "Model name used at the respective Model node, ie. \"gpt-4\""
    t.string "workflowId", limit: 36
    t.integer "executionId"
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.string "agentId", limit: 36, comment: "ID of the custom agent (if provider is \"custom-agent\")"
    t.string "status", limit: 16, default: "success", null: false, comment: "ChatHubMessageStatus enum, eg. \"success\", \"error\", \"running\", \"cancelled\""
    t.json "attachments", comment: "File attachments for the message (if any), stored as JSON. Files are stored as base64-encoded data URLs."
  end

  create_table "chat_hub_sessions", id: :uuid, default: nil, force: :cascade do |t|
    t.string "title", limit: 256, null: false
    t.uuid "ownerId", null: false
    t.timestamptz "lastMessageAt", precision: 3
    t.string "credentialId", limit: 36
    t.string "provider", limit: 16, comment: "ChatHubProvider enum: \"openai\", \"anthropic\", \"google\", \"n8n\""
    t.string "model", limit: 64, comment: "Model name used at the respective Model node, ie. \"gpt-4\""
    t.string "workflowId", limit: 36
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.string "agentId", limit: 36, comment: "ID of the custom agent (if provider is \"custom-agent\")"
    t.string "agentName", limit: 128, comment: "Cached name of the custom agent (if provider is \"custom-agent\")"
    t.json "tools", default: [], null: false, comment: "Tools available to the agent as JSON node definitions"
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
    t.text "address"
    t.string "state_registration"
    t.string "municipal_registration"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "plan_id"
    t.string "payment_method", default: "boleto", null: false
    t.index ["document"], name: "index_companies_on_document", unique: true
    t.index ["email"], name: "index_companies_on_email", unique: true
    t.index ["payment_method"], name: "index_companies_on_payment_method"
    t.index ["plan_id"], name: "index_companies_on_plan_id"
    t.index ["responsible_id"], name: "index_companies_on_responsible_id"
  end

  create_table "credentials_entity", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "name", limit: 128, null: false
    t.text "data", null: false
    t.string "type", limit: 128, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.boolean "isManaged", default: false, null: false
    t.boolean "isGlobal", default: false, null: false
    t.index ["id"], name: "pk_credentials_entity_id", unique: true
    t.index ["type"], name: "idx_07fde106c0b471d8cc80a64fc8"
  end

  create_table "data_table", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "name", limit: 128, null: false
    t.string "projectId", limit: 36, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false

    t.unique_constraint ["projectId", "name"], name: "UQ_b23096ef747281ac944d28e8b0d"
  end

  create_table "data_table_column", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "name", limit: 128, null: false
    t.string "type", limit: 32, null: false, comment: "Expected: string, number, boolean, or date (not enforced as a constraint)"
    t.integer "index", null: false, comment: "Column order, starting from 0 (0 = first column)"
    t.string "dataTableId", limit: 36, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false

    t.unique_constraint ["dataTableId", "name"], name: "UQ_8082ec4890f892f0bc77473a123"
  end

  create_table "event_destinations", id: :uuid, default: nil, force: :cascade do |t|
    t.jsonb "destination", null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
  end

  create_table "execution_annotation_tags", primary_key: ["annotationId", "tagId"], force: :cascade do |t|
    t.integer "annotationId", null: false
    t.string "tagId", limit: 24, null: false
    t.index ["annotationId"], name: "IDX_c1519757391996eb06064f0e7c"
    t.index ["tagId"], name: "IDX_a3697779b366e131b2bbdae297"
  end

  create_table "execution_annotations", id: :serial, force: :cascade do |t|
    t.integer "executionId", null: false
    t.string "vote", limit: 6
    t.text "note"
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.index ["executionId"], name: "IDX_97f863fa83c4786f1956508496", unique: true
  end

  create_table "execution_data", primary_key: "executionId", id: :integer, default: nil, force: :cascade do |t|
    t.json "workflowData", null: false
    t.text "data", null: false
  end

  create_table "execution_entity", id: :serial, force: :cascade do |t|
    t.boolean "finished", null: false
    t.string "mode", null: false
    t.string "retryOf"
    t.string "retrySuccessId"
    t.timestamptz "startedAt", precision: 3
    t.timestamptz "stoppedAt", precision: 3
    t.timestamptz "waitTill", precision: 3
    t.string "status", null: false
    t.string "workflowId", limit: 36, null: false
    t.timestamptz "deletedAt", precision: 3
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.index ["deletedAt"], name: "IDX_execution_entity_deletedAt"
    t.index ["stoppedAt", "status", "deletedAt"], name: "idx_execution_entity_stopped_at_status_deleted_at", where: "((\"stoppedAt\" IS NOT NULL) AND (\"deletedAt\" IS NULL))"
    t.index ["waitTill", "status", "deletedAt"], name: "idx_execution_entity_wait_till_status_deleted_at", where: "((\"waitTill\" IS NOT NULL) AND (\"deletedAt\" IS NULL))"
    t.index ["workflowId", "startedAt"], name: "idx_execution_entity_workflow_id_started_at", where: "((\"startedAt\" IS NOT NULL) AND (\"deletedAt\" IS NULL))"
  end

  create_table "execution_metadata", id: :integer, default: -> { "nextval('execution_metadata_temp_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "executionId", null: false
    t.string "key", limit: 255, null: false
    t.text "value", null: false
    t.index ["executionId", "key"], name: "IDX_cec8eea3bf49551482ccb4933e", unique: true
  end

  create_table "folder", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "name", limit: 128, null: false
    t.string "parentFolderId", limit: 36
    t.string "projectId", limit: 36, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.index ["projectId", "id"], name: "IDX_14f68deffaf858465715995508", unique: true
  end

  create_table "folder_tag", primary_key: ["folderId", "tagId"], force: :cascade do |t|
    t.string "folderId", limit: 36, null: false
    t.string "tagId", limit: 36, null: false
  end

  create_table "insights_by_period", id: :integer, default: nil, force: :cascade do |t|
    t.integer "metaId", null: false
    t.integer "type", null: false, comment: "0: time_saved_minutes, 1: runtime_milliseconds, 2: success, 3: failure"
    t.bigint "value", null: false
    t.integer "periodUnit", null: false, comment: "0: hour, 1: day, 2: week"
    t.timestamptz "periodStart", precision: 0, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["periodStart", "type", "periodUnit", "metaId"], name: "IDX_60b6a84299eeb3f671dfec7693", unique: true
  end

  create_table "insights_metadata", primary_key: "metaId", id: :integer, default: nil, force: :cascade do |t|
    t.string "workflowId", limit: 16
    t.string "projectId", limit: 36
    t.string "workflowName", limit: 128, null: false
    t.string "projectName", limit: 255, null: false
    t.index ["workflowId"], name: "IDX_1d8ab99d5861c9388d2dc1cf73", unique: true
  end

  create_table "insights_raw", id: :integer, default: nil, force: :cascade do |t|
    t.integer "metaId", null: false
    t.integer "type", null: false, comment: "0: time_saved_minutes, 1: runtime_milliseconds, 2: success, 3: failure"
    t.bigint "value", null: false
    t.timestamptz "timestamp", precision: 0, default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "installed_nodes", primary_key: "name", id: { type: :string, limit: 200 }, force: :cascade do |t|
    t.string "type", limit: 200, null: false
    t.integer "latestVersion", default: 1, null: false
    t.string "package", limit: 241, null: false
  end

  create_table "installed_packages", primary_key: "packageName", id: { type: :string, limit: 214 }, force: :cascade do |t|
    t.string "installedVersion", limit: 50, null: false
    t.string "authorName", limit: 70
    t.string "authorEmail", limit: 70
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
  end

  create_table "invalid_auth_token", primary_key: "token", id: { type: :string, limit: 512 }, force: :cascade do |t|
    t.timestamptz "expiresAt", precision: 3, null: false
  end

  create_table "migrations", id: :serial, force: :cascade do |t|
    t.bigint "timestamp", null: false
    t.string "name", null: false
  end

  create_table "oauth_access_tokens", primary_key: "token", id: :string, force: :cascade do |t|
    t.string "clientId", null: false
    t.uuid "userId", null: false
  end

  create_table "oauth_authorization_codes", primary_key: "code", id: { type: :string, limit: 255 }, force: :cascade do |t|
    t.string "clientId", null: false
    t.uuid "userId", null: false
    t.string "redirectUri", null: false
    t.string "codeChallenge", null: false
    t.string "codeChallengeMethod", limit: 255, null: false
    t.bigint "expiresAt", null: false, comment: "Unix timestamp in milliseconds"
    t.string "state"
    t.boolean "used", default: false, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
  end

  create_table "oauth_clients", id: :string, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.json "redirectUris", null: false
    t.json "grantTypes", null: false
    t.string "clientSecret", limit: 255
    t.bigint "clientSecretExpiresAt"
    t.string "tokenEndpointAuthMethod", limit: 255, default: "none", null: false, comment: "Possible values: none, client_secret_basic or client_secret_post"
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
  end

  create_table "oauth_refresh_tokens", primary_key: "token", id: { type: :string, limit: 255 }, force: :cascade do |t|
    t.string "clientId", null: false
    t.uuid "userId", null: false
    t.bigint "expiresAt", null: false, comment: "Unix timestamp in milliseconds"
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
  end

  create_table "oauth_user_consents", id: :integer, default: nil, force: :cascade do |t|
    t.uuid "userId", null: false
    t.string "clientId", null: false
    t.bigint "grantedAt", null: false, comment: "Unix timestamp in milliseconds"

    t.unique_constraint ["userId", "clientId"], name: "UQ_083721d99ce8db4033e2958ebb4"
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
    t.index ["client_id"], name: "index_order_services_on_client_id"
    t.index ["company_id", "code"], name: "index_order_services_on_company_id_and_code", unique: true
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
    t.index ["external_id"], name: "index_plans_on_external_id", unique: true
    t.index ["external_reference"], name: "index_plans_on_external_reference", unique: true
    t.index ["status"], name: "index_plans_on_status"
  end

  create_table "processed_data", primary_key: ["workflowId", "context"], force: :cascade do |t|
    t.string "workflowId", limit: 36, null: false
    t.string "context", limit: 255, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.text "value", null: false
  end

  create_table "project", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "type", limit: 36, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.json "icon"
    t.string "description", limit: 512
  end

  create_table "project_relation", primary_key: ["projectId", "userId"], force: :cascade do |t|
    t.string "projectId", limit: 36, null: false
    t.uuid "userId", null: false
    t.string "role", null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.index ["projectId", "role"], name: "project_relation_role_project_idx"
    t.index ["projectId"], name: "IDX_61448d56d61802b5dfde5cdb00"
    t.index ["role"], name: "project_relation_role_idx"
    t.index ["userId"], name: "IDX_5f0643f6717905a05164090dde"
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

  create_table "role", primary_key: "slug", id: { type: :string, limit: 128, comment: "Unique identifier of the role for example: \"global:owner\"" }, force: :cascade do |t|
    t.text "displayName", comment: "Name used to display in the UI"
    t.text "description", comment: "Text describing the scope in more detail of users"
    t.text "roleType", comment: "Type of the role, e.g., global, project, or workflow"
    t.boolean "systemRole", default: false, null: false, comment: "Indicates if the role is managed by the system and cannot be edited"
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.index ["displayName"], name: "IDX_UniqueRoleDisplayName", unique: true
  end

  create_table "role_scope", primary_key: ["roleSlug", "scopeSlug"], force: :cascade do |t|
    t.string "roleSlug", limit: 128, null: false
    t.string "scopeSlug", limit: 128, null: false
    t.index ["scopeSlug"], name: "IDX_role_scope_scopeSlug"
  end

  create_table "scope", primary_key: "slug", id: { type: :string, limit: 128, comment: "Unique identifier of the scope for example: \"project:create\"" }, force: :cascade do |t|
    t.text "displayName", comment: "Name used to display in the UI"
    t.text "description", comment: "Text describing the scope in more detail of users"
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

  create_table "settings", primary_key: "key", id: { type: :string, limit: 255 }, force: :cascade do |t|
    t.text "value", null: false
    t.boolean "loadOnStartup", default: false, null: false
  end

  create_table "shared_credentials", primary_key: ["credentialsId", "projectId"], force: :cascade do |t|
    t.string "credentialsId", limit: 36, null: false
    t.string "projectId", limit: 36, null: false
    t.text "role", null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
  end

  create_table "shared_workflow", primary_key: ["workflowId", "projectId"], force: :cascade do |t|
    t.string "workflowId", limit: 36, null: false
    t.string "projectId", limit: 36, null: false
    t.text "role", null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
  end

  create_table "tag_entity", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "name", limit: 24, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.index ["id"], name: "pk_tag_entity_id", unique: true
    t.index ["name"], name: "idx_812eb05f7451ca757fb98444ce", unique: true
  end

  create_table "test_case_execution", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "testRunId", limit: 36, null: false
    t.integer "executionId"
    t.string "status", null: false
    t.timestamptz "runAt", precision: 3
    t.timestamptz "completedAt", precision: 3
    t.string "errorCode"
    t.json "errorDetails"
    t.json "metrics"
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.json "inputs"
    t.json "outputs"
    t.index ["testRunId"], name: "IDX_8e4b4774db42f1e6dda3452b2a"
  end

  create_table "test_run", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "workflowId", limit: 36, null: false
    t.string "status", null: false
    t.string "errorCode"
    t.json "errorDetails"
    t.timestamptz "runAt", precision: 3
    t.timestamptz "completedAt", precision: 3
    t.json "metrics"
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.index ["workflowId"], name: "IDX_d6870d3b6e4c185d33926f423c"
  end

  create_table "user", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", limit: 255
    t.string "firstName", limit: 32
    t.string "lastName", limit: 32
    t.string "password", limit: 255
    t.json "personalizationAnswers"
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.json "settings"
    t.boolean "disabled", default: false, null: false
    t.boolean "mfaEnabled", default: false, null: false
    t.text "mfaSecret"
    t.text "mfaRecoveryCodes"
    t.date "lastActiveAt"
    t.string "roleSlug", limit: 128, default: "global:member", null: false
    t.index ["roleSlug"], name: "user_role_idx"
    t.unique_constraint ["email"], name: "UQ_e12875dfb3b1d92d7d7c5377e2"
  end

  create_table "user_api_keys", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.uuid "userId", null: false
    t.string "label", limit: 100, null: false
    t.string "apiKey", null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.json "scopes"
    t.string "audience", default: "public-api", null: false
    t.index ["apiKey"], name: "IDX_1ef35bac35d20bdae979d917a3", unique: true
    t.index ["userId", "label"], name: "IDX_63d7bbae72c767cf162d459fcc", unique: true
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
    t.index ["active"], name: "index_users_on_active"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name", "email"], name: "index_users_on_name_and_email"
    t.index ["name"], name: "index_users_on_name"
    t.index ["phone"], name: "index_users_on_phone"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "variables", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "key", limit: 50, null: false
    t.string "type", limit: 50, default: "string", null: false
    t.string "value", limit: 255
    t.string "projectId", limit: 36
    t.index ["key"], name: "variables_global_key_unique", unique: true, where: "(\"projectId\" IS NULL)"
    t.index ["projectId", "key"], name: "variables_project_key_unique", unique: true, where: "(\"projectId\" IS NOT NULL)"
  end

  create_table "webhook_entity", primary_key: ["webhookPath", "method"], force: :cascade do |t|
    t.string "webhookPath", null: false
    t.string "method", null: false
    t.string "node", null: false
    t.string "webhookId"
    t.integer "pathLength"
    t.string "workflowId", limit: 36, null: false
    t.index ["webhookId", "method", "pathLength"], name: "idx_16f4436789e804e3e1c9eeb240"
  end

  create_table "workflow_dependency", id: :integer, default: nil, force: :cascade do |t|
    t.string "workflowId", limit: 36, null: false
    t.integer "workflowVersionId", null: false, comment: "Version of the workflow"
    t.string "dependencyType", limit: 32, null: false, comment: "Type of dependency: \"credential\", \"nodeType\", \"webhookPath\", or \"workflowCall\""
    t.string "dependencyKey", limit: 255, null: false, comment: "ID or name of the dependency"
    t.json "dependencyInfo", comment: "Additional info about the dependency, interpreted based on type"
    t.integer "indexVersionId", limit: 2, default: 1, null: false, comment: "Version of the index structure"
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.index ["dependencyKey"], name: "IDX_e48a201071ab85d9d09119d640"
    t.index ["dependencyType"], name: "IDX_e7fe1cfda990c14a445937d0b9"
    t.index ["workflowId"], name: "IDX_a4ff2d9b9628ea988fa9e7d0bf"
  end

  create_table "workflow_entity", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "name", limit: 128, null: false
    t.boolean "active", null: false
    t.json "nodes", null: false
    t.json "connections", null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.json "settings"
    t.json "staticData"
    t.json "pinData"
    t.string "versionId", limit: 36, null: false
    t.integer "triggerCount", default: 0, null: false
    t.json "meta"
    t.string "parentFolderId", limit: 36
    t.boolean "isArchived", default: false, null: false
    t.integer "versionCounter", default: 1, null: false
    t.text "description"
    t.string "activeVersionId", limit: 36
    t.index ["id"], name: "pk_workflow_entity_id", unique: true
    t.index ["name"], name: "IDX_workflow_entity_name"
  end

  create_table "workflow_history", primary_key: "versionId", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "workflowId", limit: 36, null: false
    t.string "authors", limit: 255, null: false
    t.timestamptz "createdAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.timestamptz "updatedAt", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }, null: false
    t.json "nodes", null: false
    t.json "connections", null: false
    t.string "name", limit: 128
    t.boolean "autosaved", default: false, null: false
    t.text "description"
    t.index ["workflowId"], name: "IDX_1e31657f5fe46816c34be7c1b4"
  end

  create_table "workflow_statistics", primary_key: ["workflowId", "name"], force: :cascade do |t|
    t.integer "count", default: 0
    t.timestamptz "latestEvent", precision: 3
    t.string "name", limit: 128, null: false
    t.string "workflowId", limit: 36, null: false
    t.integer "rootCount", default: 0
  end

  create_table "workflows_tags", primary_key: ["workflowId", "tagId"], force: :cascade do |t|
    t.string "workflowId", limit: 36, null: false
    t.string "tagId", limit: 36, null: false
    t.index ["workflowId"], name: "idx_workflows_tags_workflow_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "clients", on_delete: :cascade
  add_foreign_key "assignments", "order_services"
  add_foreign_key "assignments", "users"
  add_foreign_key "auth_identity", "user", column: "userId", name: "auth_identity_userId_fkey"
  add_foreign_key "chat_hub_agents", "credentials_entity", column: "credentialId", name: "FK_9c61ad497dcbae499c96a6a78ba", on_delete: :nullify
  add_foreign_key "chat_hub_agents", "user", column: "ownerId", name: "FK_441ba2caba11e077ce3fbfa2cd8", on_delete: :cascade
  add_foreign_key "chat_hub_messages", "chat_hub_messages", column: "previousMessageId", name: "FK_e5d1fa722c5a8d38ac204746662", on_delete: :cascade
  add_foreign_key "chat_hub_messages", "chat_hub_messages", column: "retryOfMessageId", name: "FK_25c9736e7f769f3a005eef4b372", on_delete: :cascade
  add_foreign_key "chat_hub_messages", "chat_hub_messages", column: "revisionOfMessageId", name: "FK_1f4998c8a7dec9e00a9ab15550e", on_delete: :cascade
  add_foreign_key "chat_hub_messages", "chat_hub_sessions", column: "sessionId", name: "FK_e22538eb50a71a17954cd7e076c", on_delete: :cascade
  add_foreign_key "chat_hub_messages", "execution_entity", column: "executionId", name: "FK_6afb260449dd7a9b85355d4e0c9", on_delete: :nullify
  add_foreign_key "chat_hub_messages", "workflow_entity", column: "workflowId", name: "FK_acf8926098f063cdbbad8497fd1", on_delete: :nullify
  add_foreign_key "chat_hub_sessions", "credentials_entity", column: "credentialId", name: "FK_7bc13b4c7e6afbfaf9be326c189", on_delete: :nullify
  add_foreign_key "chat_hub_sessions", "user", column: "ownerId", name: "FK_e9ecf8ede7d989fcd18790fe36a", on_delete: :cascade
  add_foreign_key "chat_hub_sessions", "workflow_entity", column: "workflowId", name: "FK_9f9293d9f552496c40e0d1a8f80", on_delete: :nullify
  add_foreign_key "clients", "companies"
  add_foreign_key "companies", "plans"
  add_foreign_key "companies", "users", column: "responsible_id"
  add_foreign_key "data_table", "project", column: "projectId", name: "FK_c2a794257dee48af7c9abf681de", on_delete: :cascade
  add_foreign_key "data_table_column", "data_table", column: "dataTableId", name: "FK_930b6e8faaf88294cef23484160", on_delete: :cascade
  add_foreign_key "execution_annotation_tags", "annotation_tag_entity", column: "tagId", name: "FK_a3697779b366e131b2bbdae2976", on_delete: :cascade
  add_foreign_key "execution_annotation_tags", "execution_annotations", column: "annotationId", name: "FK_c1519757391996eb06064f0e7c8", on_delete: :cascade
  add_foreign_key "execution_annotations", "execution_entity", column: "executionId", name: "FK_97f863fa83c4786f19565084960", on_delete: :cascade
  add_foreign_key "execution_data", "execution_entity", column: "executionId", name: "execution_data_fk", on_delete: :cascade
  add_foreign_key "execution_entity", "workflow_entity", column: "workflowId", name: "fk_execution_entity_workflow_id", on_delete: :cascade
  add_foreign_key "execution_metadata", "execution_entity", column: "executionId", name: "FK_31d0b4c93fb85ced26f6005cda3", on_delete: :cascade
  add_foreign_key "folder", "folder", column: "parentFolderId", name: "FK_804ea52f6729e3940498bd54d78", on_delete: :cascade
  add_foreign_key "folder", "project", column: "projectId", name: "FK_a8260b0b36939c6247f385b8221", on_delete: :cascade
  add_foreign_key "folder_tag", "folder", column: "folderId", name: "FK_94a60854e06f2897b2e0d39edba", on_delete: :cascade
  add_foreign_key "folder_tag", "tag_entity", column: "tagId", name: "FK_dc88164176283de80af47621746", on_delete: :cascade
  add_foreign_key "insights_by_period", "insights_metadata", column: "metaId", primary_key: "metaId", name: "FK_6414cfed98daabbfdd61a1cfbc0", on_delete: :cascade
  add_foreign_key "insights_metadata", "project", column: "projectId", name: "FK_2375a1eda085adb16b24615b69c", on_delete: :nullify
  add_foreign_key "insights_metadata", "workflow_entity", column: "workflowId", name: "FK_1d8ab99d5861c9388d2dc1cf733", on_delete: :nullify
  add_foreign_key "insights_raw", "insights_metadata", column: "metaId", primary_key: "metaId", name: "FK_6e2e33741adef2a7c5d66befa4e", on_delete: :cascade
  add_foreign_key "installed_nodes", "installed_packages", column: "package", primary_key: "packageName", name: "FK_73f857fc5dce682cef8a99c11dbddbc969618951", on_update: :cascade, on_delete: :cascade
  add_foreign_key "oauth_access_tokens", "oauth_clients", column: "clientId", name: "FK_78b26968132b7e5e45b75876481", on_delete: :cascade
  add_foreign_key "oauth_access_tokens", "user", column: "userId", name: "FK_7234a36d8e49a1fa85095328845", on_delete: :cascade
  add_foreign_key "oauth_authorization_codes", "oauth_clients", column: "clientId", name: "FK_64d965bd072ea24fb6da55468cd", on_delete: :cascade
  add_foreign_key "oauth_authorization_codes", "user", column: "userId", name: "FK_aa8d3560484944c19bdf79ffa16", on_delete: :cascade
  add_foreign_key "oauth_refresh_tokens", "oauth_clients", column: "clientId", name: "FK_b388696ce4d8be7ffbe8d3e4b69", on_delete: :cascade
  add_foreign_key "oauth_refresh_tokens", "user", column: "userId", name: "FK_a699f3ed9fd0c1b19bc2608ac53", on_delete: :cascade
  add_foreign_key "oauth_user_consents", "oauth_clients", column: "clientId", name: "FK_a651acea2f6c97f8c4514935486", on_delete: :cascade
  add_foreign_key "oauth_user_consents", "user", column: "userId", name: "FK_21e6c3c2d78a097478fae6aaefa", on_delete: :cascade
  add_foreign_key "order_services", "clients"
  add_foreign_key "order_services", "companies"
  add_foreign_key "processed_data", "workflow_entity", column: "workflowId", name: "FK_06a69a7032c97a763c2c7599464", on_delete: :cascade
  add_foreign_key "project_relation", "project", column: "projectId", name: "FK_61448d56d61802b5dfde5cdb002", on_delete: :cascade
  add_foreign_key "project_relation", "role", column: "role", primary_key: "slug", name: "FK_c6b99592dc96b0d836d7a21db91"
  add_foreign_key "project_relation", "user", column: "userId", name: "FK_5f0643f6717905a05164090dde7", on_delete: :cascade
  add_foreign_key "reports", "companies"
  add_foreign_key "reports", "users"
  add_foreign_key "role_scope", "role", column: "roleSlug", primary_key: "slug", name: "FK_role", on_update: :cascade, on_delete: :cascade
  add_foreign_key "role_scope", "scope", column: "scopeSlug", primary_key: "slug", name: "FK_scope", on_update: :cascade, on_delete: :cascade
  add_foreign_key "service_items", "order_services"
  add_foreign_key "shared_credentials", "credentials_entity", column: "credentialsId", name: "FK_416f66fc846c7c442970c094ccf", on_delete: :cascade
  add_foreign_key "shared_credentials", "project", column: "projectId", name: "FK_812c2852270da1247756e77f5a4", on_delete: :cascade
  add_foreign_key "shared_workflow", "project", column: "projectId", name: "FK_a45ea5f27bcfdc21af9b4188560", on_delete: :cascade
  add_foreign_key "shared_workflow", "workflow_entity", column: "workflowId", name: "FK_daa206a04983d47d0a9c34649ce", on_delete: :cascade
  add_foreign_key "test_case_execution", "execution_entity", column: "executionId", name: "FK_e48965fac35d0f5b9e7f51d8c44", on_delete: :nullify
  add_foreign_key "test_case_execution", "test_run", column: "testRunId", name: "FK_8e4b4774db42f1e6dda3452b2af", on_delete: :cascade
  add_foreign_key "test_run", "workflow_entity", column: "workflowId", name: "FK_d6870d3b6e4c185d33926f423c8", on_delete: :cascade
  add_foreign_key "user", "role", column: "roleSlug", primary_key: "slug", name: "FK_eaea92ee7bfb9c1b6cd01505d56"
  add_foreign_key "user_api_keys", "user", column: "userId", name: "FK_e131705cbbc8fb589889b02d457", on_delete: :cascade
  add_foreign_key "users", "companies"
  add_foreign_key "variables", "project", column: "projectId", name: "FK_42f6c766f9f9d2edcc15bdd6e9b", on_delete: :cascade
  add_foreign_key "webhook_entity", "workflow_entity", column: "workflowId", name: "fk_webhook_entity_workflow_id", on_delete: :cascade
  add_foreign_key "workflow_dependency", "workflow_entity", column: "workflowId", name: "FK_a4ff2d9b9628ea988fa9e7d0bf8", on_delete: :cascade
  add_foreign_key "workflow_entity", "folder", column: "parentFolderId", name: "fk_workflow_parent_folder", on_delete: :cascade
  add_foreign_key "workflow_entity", "workflow_history", column: "activeVersionId", primary_key: "versionId", name: "FK_08d6c67b7f722b0039d9d5ed620", on_delete: :restrict
  add_foreign_key "workflow_history", "workflow_entity", column: "workflowId", name: "FK_1e31657f5fe46816c34be7c1b4b", on_delete: :cascade
  add_foreign_key "workflow_statistics", "workflow_entity", column: "workflowId", name: "fk_workflow_statistics_workflow_id", on_delete: :cascade
  add_foreign_key "workflows_tags", "tag_entity", column: "tagId", name: "fk_workflows_tags_tag_id", on_delete: :cascade
  add_foreign_key "workflows_tags", "workflow_entity", column: "workflowId", name: "fk_workflows_tags_workflow_id", on_delete: :cascade
end
