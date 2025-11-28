class AddSlugToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :slug, :string
    add_index :recipes, :slug, unique: true
  end
end
