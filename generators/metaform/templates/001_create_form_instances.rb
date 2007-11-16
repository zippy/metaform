class CreateFormInstances < ActiveRecord::Migration
  def self.up
    create_table :form_instances do |t|
      t.column :form_id, :string, :null => false
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :created_by_id, :integer
      t.column :updated_by_id, :integer
      t.column :workflow_state, :string
      t.column :workflow, :string
    end
    add_index :form_instances, :workflow_state
    add_index :form_instances, :form_id
  end

  def self.down
    remove_index :form_instances, :workflow_state
    remove_index :form_instances, :form_id
    drop_table :form_instances
  end
end
