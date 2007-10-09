class CreateFieldInstances < ActiveRecord::Migration
  def self.up
    create_table :field_instances do |t|
      t.column :field_id, :string, :null => false
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :created_by_id, :integer
      t.column :updated_by_id, :integer
      t.column :field_id, :integer
      t.column :answer, :text
      t.column :state, :string
      t.column :explanation, :text
    end
  end

  def self.down
    drop_table :field_instances
  end
end
