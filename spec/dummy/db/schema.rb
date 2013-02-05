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

ActiveRecord::Schema.define(:version => 2) do

  create_table "field_instances", :force => true do |t|
    t.integer  "form_instance_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "field_id"
    t.text     "answer"
    t.string   "state"
    t.text     "explanation"
    t.integer  "idx",              :default => 0, :null => false
  end

  create_table "form_instances", :force => true do |t|
    t.string   "form_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "workflow"
    t.string   "workflow_state"
    t.text     "validation_data"
  end

end
