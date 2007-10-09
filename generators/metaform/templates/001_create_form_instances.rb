class CreateFormInstances < ActiveRecord::Migration
  def self.up
    create_table :form_instances do |t|
      t.column :form_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :created_by_id, :integer
      t.column :updated_by_id, :integer
      t.column :workflow_state, :string
    end
  end

  def self.down
    drop_table :form_instances
  end
end
