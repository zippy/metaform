class CreateFormInstances < ActiveRecord::Migration
  def self.up
    create_table :form_instances do |t|
      t.string   :form_id
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :created_by_id
      t.integer  :updated_by_id
      t.string   :workflow
      t.string   :workflow_state
      t.text     :validation_data
    end
  end

  def self.down
    drop_table :form_instances
  end
end
