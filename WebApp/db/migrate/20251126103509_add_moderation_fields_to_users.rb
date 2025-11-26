class AddModerationFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :blocked, :boolean, default: false, null: false
    add_column :users, :blocked_at, :datetime
    add_column :users, :blocked_reason, :text
    add_column :users, :suspension_count, :integer, default: 0, null: false
    add_column :users, :reports_count, :integer, default: 0, null: false
    
    add_index :users, :blocked
  end
end
