class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notification_type
      t.string :title
      t.text :message
      t.integer :recipe_id
      t.boolean :read, default: false, null: false

      t.timestamps
    end
    
    add_index :notifications, :read
    add_index :notifications, :created_at
    add_index :notifications, :recipe_id
  end
end
