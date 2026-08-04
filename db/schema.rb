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

ActiveRecord::Schema[8.1].define(version: 2026_08_04_202650) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "carpools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "destination"
    t.text "details"
    t.string "name", null: false
    t.string "public_id", null: false
    t.datetime "return_starts_at"
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["public_id"], name: "index_carpools_on_public_id", unique: true
    t.index ["user_id"], name: "index_carpools_on_user_id"
  end

  create_table "ride_claims", force: :cascade do |t|
    t.bigint "carpool_id", null: false
    t.datetime "created_at", null: false
    t.string "direction", default: "outbound", null: false
    t.string "pickup_location"
    t.bigint "ride_id", null: false
    t.integer "seats", default: 1, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["carpool_id", "user_id", "direction"], name: "index_ride_claims_on_carpool_id_and_user_id_and_direction", unique: true
    t.index ["carpool_id"], name: "index_ride_claims_on_carpool_id"
    t.index ["ride_id"], name: "index_ride_claims_on_ride_id"
    t.index ["user_id"], name: "index_ride_claims_on_user_id"
  end

  create_table "rides", force: :cascade do |t|
    t.bigint "carpool_id", null: false
    t.datetime "created_at", null: false
    t.datetime "departure_time"
    t.string "direction", default: "outbound", null: false
    t.text "notes"
    t.string "origin"
    t.string "role", null: false
    t.integer "seats", default: 1, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["carpool_id", "user_id", "direction"], name: "index_rides_on_carpool_id_and_user_id_and_direction", unique: true
    t.index ["carpool_id"], name: "index_rides_on_carpool_id"
    t.index ["user_id"], name: "index_rides_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "email_confirmed_at"
    t.string "name", null: false
    t.string "pending_email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "carpools", "users"
  add_foreign_key "ride_claims", "carpools"
  add_foreign_key "ride_claims", "rides"
  add_foreign_key "ride_claims", "users"
  add_foreign_key "rides", "carpools"
  add_foreign_key "rides", "users"
end
