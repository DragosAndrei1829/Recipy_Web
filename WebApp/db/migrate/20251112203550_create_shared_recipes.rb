class CreateSharedRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :shared_recipes do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :recipe, null: false, foreign_key: true
      t.text :message
      t.boolean :read, default: false, null: false

      t.timestamps
    end
    
    add_index :shared_recipes, [:recipient_id, :read, :created_at]
    add_index :shared_recipes, :created_at
  end
end
