class AddIndexToMessagesRecipeId < ActiveRecord::Migration[8.1]
  def change
    add_index :messages, :recipe_id
  end
end
