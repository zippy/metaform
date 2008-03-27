ActiveRecord::Schema.define(:version => 0) do
  create_table "field_instances", :force => true do |t|
    t.integer  "form_instance_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "field_id",         :default => "", :null => false
    t.text     "answer"
    t.string   "state"
    t.text     "explanation"
    t.string   "idx"
  end

  add_index "field_instances", ["idx"], :name => "index_field_instances_on_idx"

  create_table "form_instances", :force => true do |t|
    t.string   "form_id",        :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "workflow_state"
    t.string   "workflow"
  end
end
