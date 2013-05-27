# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130518205559) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "brand_portfolios", :force => true do |t|
    t.string   "name"
    t.boolean  "active"
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "brand_portfolios", ["company_id"], :name => "index_brand_portfolios_on_company_id"

  create_table "brand_portfolios_brands", :force => true do |t|
    t.integer "brand_id"
    t.integer "brand_portfolio_id"
  end

  add_index "brand_portfolios_brands", ["brand_id", "brand_portfolio_id"], :name => "brand_portfolio_unique_idx", :unique => true
  add_index "brand_portfolios_brands", ["brand_id"], :name => "index_brand_portfolios_brands_on_brand_id"
  add_index "brand_portfolios_brands", ["brand_portfolio_id"], :name => "index_brand_portfolios_brands_on_brand_portfolio_id"

  create_table "brands", :force => true do |t|
    t.string   "name"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "brands_campaigns", :force => true do |t|
    t.integer "brand_id"
    t.integer "campaign_id"
  end

  add_index "brands_campaigns", ["brand_id"], :name => "index_brands_campaigns_on_brand_id"
  add_index "brands_campaigns", ["campaign_id"], :name => "index_brands_campaigns_on_campaign_id"

  create_table "campaigns", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "aasm_state"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "company_id"
  end

  add_index "campaigns", ["company_id"], :name => "index_campaigns_on_company_id"

  create_table "campaigns_teams", :force => true do |t|
    t.integer "campaign_id"
    t.integer "team_id"
  end

  add_index "campaigns_teams", ["campaign_id"], :name => "index_campaigns_teams_on_campaign_id"
  add_index "campaigns_teams", ["team_id"], :name => "index_campaigns_teams_on_team_id"

  create_table "comments", :force => true do |t|
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.text     "content"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "comments", ["commentable_type", "commentable_id"], :name => "index_comments_on_commentable_type_and_commentable_id"

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "company_users", :force => true do |t|
    t.integer  "company_id"
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.boolean  "active",     :default => true
  end

  add_index "company_users", ["company_id"], :name => "index_company_users_on_company_id"
  add_index "company_users", ["user_id"], :name => "index_company_users_on_user_id"

  create_table "documents", :force => true do |t|
    t.string   "name"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "documentable_id"
    t.string   "documentable_type"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "documents", ["documentable_type", "documentable_id"], :name => "index_documents_on_documentable_type_and_documentable_id"

  create_table "events", :force => true do |t|
    t.integer  "campaign_id"
    t.integer  "company_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.string   "aasm_state"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.boolean  "active",        :default => true
    t.integer  "place_id"
  end

  add_index "events", ["campaign_id"], :name => "index_events_on_campaign_id"
  add_index "events", ["place_id"], :name => "index_events_on_place_id"

  create_table "events_users", :force => true do |t|
    t.integer "event_id"
    t.integer "user_id"
  end

  add_index "events_users", ["event_id"], :name => "index_events_users_on_event_id"
  add_index "events_users", ["user_id"], :name => "index_events_users_on_user_id"

  create_table "places", :force => true do |t|
    t.string   "name"
    t.string   "reference",         :limit => 400
    t.string   "place_id",          :limit => 100
    t.string   "types"
    t.string   "formatted_address"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "street_number"
    t.string   "route"
    t.string   "zipcode"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "places", ["reference"], :name => "index_places_on_reference"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.text     "permissions"
    t.integer  "company_id"
    t.boolean  "active",      :default => true
    t.text     "description"
  end

  create_table "tasks", :force => true do |t|
    t.integer  "event_id"
    t.string   "title"
    t.datetime "due_at"
    t.integer  "user_id"
    t.boolean  "completed",     :default => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.boolean  "active",        :default => true
  end

  add_index "tasks", ["event_id"], :name => "index_tasks_on_event_id"
  add_index "tasks", ["user_id"], :name => "index_tasks_on_user_id"

  create_table "teams", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.boolean  "active",        :default => true
    t.integer  "company_id"
  end

  add_index "teams", ["company_id"], :name => "index_teams_on_company_id"

  create_table "teams_users", :force => true do |t|
    t.integer  "team_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "teams_users", ["team_id"], :name => "index_teams_users_on_team_id"
  add_index "teams_users", ["user_id"], :name => "index_teams_users_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",                  :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.string   "country",                :limit => 4
    t.string   "state"
    t.string   "city"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "last_activity_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
