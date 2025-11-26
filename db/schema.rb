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

ActiveRecord::Schema[8.1].define(version: 2025_11_26_103513) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "rating", default: 0, null: false
    t.bigint "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["recipe_id"], name: "index_comments_on_recipe_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "recipient_id", null: false
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_conversations_on_created_at"
    t.index ["recipient_id"], name: "index_conversations_on_recipient_id"
    t.index ["sender_id", "recipient_id"], name: "index_conversations_on_sender_id_and_recipient_id", unique: true
    t.index ["sender_id"], name: "index_conversations_on_sender_id"
  end

  create_table "cuisines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_cuisines_on_name"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["recipe_id"], name: "index_favorites_on_recipe_id"
    t.index ["user_id", "recipe_id"], name: "index_favorites_on_user_id_and_recipe_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "follower_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["follower_id"], name: "index_follows_on_follower_id"
    t.index ["user_id", "follower_id"], name: "index_follows_on_user_id_and_follower_id", unique: true
    t.index ["user_id"], name: "index_follows_on_user_id"
  end

  create_table "food_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_food_types_on_name"
  end

  create_table "legal_contents", force: :cascade do |t|
    t.boolean "active"
    t.text "content_en"
    t.text "content_ro"
    t.datetime "created_at", null: false
    t.text "full_content_en"
    t.text "full_content_ro"
    t.string "key"
    t.string "page_type"
    t.integer "section_order"
    t.string "title_en"
    t.string "title_ro"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_legal_contents_on_key", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["recipe_id"], name: "index_likes_on_recipe_id"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.boolean "read", default: false, null: false
    t.bigint "recipe_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["read"], name: "index_messages_on_read"
    t.index ["recipe_id"], name: "index_messages_on_recipe_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message"
    t.string "notification_type"
    t.boolean "read", default: false, null: false
    t.integer "recipe_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["read"], name: "index_notifications_on_read"
    t.index ["recipe_id"], name: "index_notifications_on_recipe_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.bigint "category_id"
    t.integer "comments_count", default: 0, null: false
    t.bigint "cover_photo_id"
    t.datetime "created_at", null: false
    t.bigint "cuisine_id"
    t.text "description"
    t.integer "difficulty", default: 0, null: false
    t.bigint "food_type_id"
    t.integer "healthiness", default: 0, null: false
    t.text "ingredients"
    t.integer "likes_count", default: 0, null: false
    t.json "nutrition"
    t.json "photos_order"
    t.text "preparation"
    t.text "quarantine_reason"
    t.boolean "quarantined", default: false, null: false
    t.datetime "quarantined_at"
    t.integer "reports_count", default: 0, null: false
    t.integer "time_to_make", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "index_recipes_on_category_id"
    t.index ["cuisine_id"], name: "index_recipes_on_cuisine_id"
    t.index ["food_type_id"], name: "index_recipes_on_food_type_id"
    t.index ["quarantined"], name: "index_recipes_on_quarantined"
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "reason", null: false
    t.bigint "reportable_id", null: false
    t.string "reportable_type", null: false
    t.bigint "reporter_id", null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["reportable_type", "reportable_id", "reporter_id"], name: "index_reports_unique_per_reporter", unique: true
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["reviewed_by_id"], name: "index_reports_on_reviewed_by_id"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "shared_recipes", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.text "message"
    t.boolean "read", default: false, null: false
    t.bigint "recipe_id", null: false
    t.bigint "recipient_id", null: false
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_shared_recipes_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_shared_recipes_on_conversation_id"
    t.index ["created_at"], name: "index_shared_recipes_on_created_at"
    t.index ["recipe_id"], name: "index_shared_recipes_on_recipe_id"
    t.index ["recipient_id", "read", "created_at"], name: "index_shared_recipes_on_recipient_id_and_read_and_created_at"
    t.index ["recipient_id"], name: "index_shared_recipes_on_recipient_id"
    t.index ["sender_id"], name: "index_shared_recipes_on_sender_id"
  end

  create_table "site_settings", force: :cascade do |t|
    t.string "accent_color"
    t.string "background_color", default: "#f0fdf4"
    t.string "border_color", default: "#e5e7eb"
    t.string "button_color", default: "#10b981"
    t.string "card_background", default: "#ffffff"
    t.text "contact_address"
    t.string "contact_email"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.string "error_color", default: "#ef4444"
    t.string "footer_background", default: "#0f172a"
    t.string "footer_link", default: "#ffffff"
    t.string "footer_link_hover", default: "#a5b4fc"
    t.string "footer_text", default: "#ffffff"
    t.string "link_color", default: "#059669"
    t.string "navbar_color", default: "#ffffff"
    t.string "primary_color"
    t.string "secondary_color"
    t.string "success_color", default: "#10b981"
    t.string "text_primary", default: "#111827"
    t.string "text_secondary", default: "#6b7280"
    t.integer "theme_id"
    t.datetime "updated_at", null: false
    t.string "warning_color", default: "#f59e0b"
  end

  create_table "themes", force: :cascade do |t|
    t.string "accent_color", default: "#06b6d4"
    t.string "background_color", default: "#f0fdf4"
    t.string "border_color", default: "#e5e7eb"
    t.string "button_color", default: "#10b981"
    t.string "card_background", default: "#ffffff"
    t.datetime "created_at", null: false
    t.string "error_color", default: "#ef4444"
    t.boolean "is_default", default: false
    t.string "link_color", default: "#059669"
    t.string "name", null: false
    t.string "navbar_color", default: "#ffffff"
    t.string "primary_color", default: "#10b981"
    t.string "secondary_color", default: "#14b8a6"
    t.string "success_color", default: "#10b981"
    t.string "text_primary", default: "#111827"
    t.string "text_secondary", default: "#6b7280"
    t.datetime "updated_at", null: false
    t.string "warning_color", default: "#f59e0b"
  end

  create_table "users", force: :cascade do |t|
    t.string "account_type"
    t.boolean "admin", default: false, null: false
    t.boolean "blocked", default: false, null: false
    t.datetime "blocked_at"
    t.text "blocked_reason"
    t.string "confirmation_code"
    t.datetime "confirmation_code_sent_at"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "locked_at"
    t.string "phone"
    t.boolean "privacy_policy_accepted", default: false, null: false
    t.datetime "privacy_policy_accepted_at"
    t.string "provider"
    t.datetime "remember_created_at"
    t.integer "reports_count", default: 0, null: false
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "suspension_count", default: 0, null: false
    t.boolean "terms_accepted", default: false, null: false
    t.datetime "terms_accepted_at"
    t.integer "theme_id"
    t.string "uid"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["blocked"], name: "index_users_on_blocked"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "recipes"
  add_foreign_key "comments", "users"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "conversations", "users", column: "sender_id"
  add_foreign_key "favorites", "recipes"
  add_foreign_key "favorites", "users"
  add_foreign_key "follows", "users"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "likes", "recipes"
  add_foreign_key "likes", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "recipes", "categories"
  add_foreign_key "recipes", "cuisines"
  add_foreign_key "recipes", "food_types"
  add_foreign_key "recipes", "users"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "reports", "users", column: "reviewed_by_id"
  add_foreign_key "shared_recipes", "conversations"
  add_foreign_key "shared_recipes", "recipes"
  add_foreign_key "shared_recipes", "users", column: "recipient_id"
  add_foreign_key "shared_recipes", "users", column: "sender_id"
end
