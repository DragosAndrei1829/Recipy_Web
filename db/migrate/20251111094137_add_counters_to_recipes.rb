class AddCountersToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :comments_count, :integer, default: 0, null: false
    add_column :recipes, :likes_count, :integer, default: 0, null: false
  end
end
