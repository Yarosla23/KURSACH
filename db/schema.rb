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

ActiveRecord::Schema[8.0].define(version: 2026_03_25_202804) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "adjacency_matrices", force: :cascade do |t|
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "experiment_id", null: false
    t.index ["experiment_id"], name: "index_adjacency_matrices_on_experiment_id"
  end

  create_table "attacks", force: :cascade do |t|
    t.string "attack_type"
    t.float "a"
    t.float "b"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "experiment_results", force: :cascade do |t|
    t.bigint "experiment_id", null: false
    t.integer "t"
    t.float "p_attack"
    t.float "p_single"
    t.float "p_collab"
    t.float "p_single_counter"
    t.float "p_collab_counter"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["experiment_id"], name: "index_experiment_results_on_experiment_id"
  end

  create_table "experiments", force: :cascade do |t|
    t.bigint "attacks_id", null: false
    t.float "p_single"
    t.float "p_ai"
    t.integer "n"
    t.integer "k"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attacks_id"], name: "index_experiments_on_attacks_id"
  end

  create_table "matrix_edges", force: :cascade do |t|
    t.bigint "adjacency_matrix_id", null: false
    t.integer "x"
    t.integer "y"
    t.integer "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["adjacency_matrix_id"], name: "index_matrix_edges_on_adjacency_matrix_id"
  end

  add_foreign_key "adjacency_matrices", "experiments"
  add_foreign_key "experiment_results", "experiments"
  add_foreign_key "experiments", "attacks", column: "attacks_id"
  add_foreign_key "matrix_edges", "adjacency_matrices"
end
