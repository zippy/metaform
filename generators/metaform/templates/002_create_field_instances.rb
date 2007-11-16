class CreateFieldInstances < ActiveRecord::Migration
  def self.up
    create_table :field_instances do |t|
      t.column :form_instance_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :created_by_id, :integer
      t.column :updated_by_id, :integer
      t.column :field_id, :string, :null => false
      t.column :answer, :text
      t.column :state, :string
      t.column :explanation, :text
      t.column :idx, :integer
    end
    add_index :field_instances, :form_instance_id
    add_index :field_instances, :field_id
    add_index :field_instances, :idx
  end

  def self.down
    remove_index :field_instances, :form_instance_id
    remove_index :field_instances, :field_id
    remove_index :field_instances, :idx
    drop_table :field_instances
  end
end