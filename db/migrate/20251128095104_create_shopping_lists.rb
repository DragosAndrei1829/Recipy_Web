class CreateShoppingLists < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false, default: "Lista de cumpărături"
      t.string :status, null: false, default: "active" # active, completed, archived
      t.datetime :completed_at
      t.integer :items_count, default: 0, null: false
      t.integer :checked_items_count, default: 0, null: false

      t.timestamps
    end
    
    add_index :shopping_lists, [:user_id, :status]
    add_index :shopping_lists, :status
  end
end
