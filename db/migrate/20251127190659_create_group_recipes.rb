class CreateGroupRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :group_recipes do |t|
      t.references :group, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.references :added_by, null: false, foreign_key: { to_table: :users }
      t.text :note

      t.timestamps
    end

    # Ensure a recipe can only be added to a group once
    add_index :group_recipes, [:group_id, :recipe_id], unique: true
  end
end
