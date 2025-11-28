class CreateShoppingListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_list_items do |t|
      t.references :shopping_list, null: false, foreign_key: true
      t.string :ingredient_name, null: false
      t.string :quantity
      t.string :unit
      t.string :category # vegetables, fruits, meat, dairy, etc.
      t.boolean :checked, default: false, null: false
      t.integer :position, default: 0, null: false
      t.references :recipe, null: true, foreign_key: true # Optional: track which recipe this came from

      t.timestamps
    end
    
    add_index :shopping_list_items, [:shopping_list_id, :checked]
    add_index :shopping_list_items, :category
    add_index :shopping_list_items, :position
  end
end
