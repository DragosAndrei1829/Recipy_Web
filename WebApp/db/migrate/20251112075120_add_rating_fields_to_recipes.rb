class AddRatingFieldsToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :difficulty, :integer, default: 0, null: false
    add_column :recipes, :time_to_make, :integer, default: 0, null: false
    add_column :recipes, :healthiness, :integer, default: 0, null: false
  end
end
