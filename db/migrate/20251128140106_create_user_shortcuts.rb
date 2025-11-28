class CreateUserShortcuts < ActiveRecord::Migration[8.1]
  def change
    create_table :user_shortcuts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url, null: false
      t.string :color, default: '#3b82f6' # Default blue
      t.string :icon, default: '🔗' # Default link icon
      t.integer :position, default: 0

      t.timestamps
    end
    
    add_index :user_shortcuts, [:user_id, :position]
  end
end
