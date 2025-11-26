class AddRecipeIdToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :recipe_id, :bigint
  end
end
