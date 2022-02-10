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

ActiveRecord::Schema[7.0].define(version: 2016_12_28_212306) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.text "short_description"
    t.text "description", null: false
    t.boolean "is_public", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_campaigns_on_user_id"
  end

  create_table "campaigns_users", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.integer "user_id", null: false
    t.index ["campaign_id", "user_id"], name: "index_campaigns_users_on_campaign_id_and_user_id", unique: true
  end

  create_table "content_texts", force: :cascade do |t|
    t.text "content", null: false
    t.integer "ordering"
    t.integer "visibility", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "hierarchy_element_id"
    t.index ["hierarchy_element_id"], name: "index_content_texts_on_hierarchy_element_id"
    t.index ["visibility"], name: "index_content_texts_on_visibility"
  end

  create_table "content_texts_users", id: false, force: :cascade do |t|
    t.bigint "content_text_id", null: false
    t.bigint "user_id", null: false
    t.index ["content_text_id", "user_id"], name: "content_texts_users_uniqueness", unique: true
    t.index ["content_text_id"], name: "index_content_texts_users_on_content_text_id"
    t.index ["user_id"], name: "index_content_texts_users_on_user_id"
  end

  create_table "hierarchy_elements", force: :cascade do |t|
    t.string "name", null: false
    t.integer "visibility", default: 0, null: false
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "hierarchable_type"
    t.bigint "hierarchable_id"
    t.index ["hierarchable_type", "hierarchable_id"], name: "index_hierachy_elements_on_hierarchable"
    t.index ["visibility"], name: "index_hierarchy_elements_on_visibility"
  end

  create_table "hierarchy_elements_users", id: false, force: :cascade do |t|
    t.bigint "hierarchy_element_id", null: false
    t.bigint "user_id", null: false
    t.index ["hierarchy_element_id", "user_id"], name: "hierarchy_elements_users_uniqueness", unique: true
    t.index ["hierarchy_element_id"], name: "index_hierarchy_elements_users_on_hierarchy_element_id"
    t.index ["user_id"], name: "index_hierarchy_elements_users_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "remember_token"
    t.string "locale", default: "en", null: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token", unique: true
  end

end
