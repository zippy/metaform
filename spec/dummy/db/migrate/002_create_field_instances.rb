class CreateFieldInstances < ActiveRecord::Migration
  def self.up
    create_table :field_instances do |t|
      t.integer  :form_instance_id
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :created_by_id
      t.integer  :updated_by_id
      t.string   :field_id
      t.text     :answer
      t.string   :state
      t.text     :explanation
      t.integer  :idx, :default => 0, :null => false
    end
  end

  def self.down
    drop_table :field_instances
  end
end
