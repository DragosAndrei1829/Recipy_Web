class AddConversationToSharedRecipes < ActiveRecord::Migration[8.1]
  def up
    # Add column as nullable first
    add_reference :shared_recipes, :conversation, null: true, foreign_key: true
    
    # Populate existing shared_recipes with conversations
    SharedRecipe.find_each do |shared_recipe|
      conversation = Conversation.between(shared_recipe.sender, shared_recipe.recipient).first
      unless conversation
        conversation = Conversation.create!(
          sender: shared_recipe.sender,
          recipient: shared_recipe.recipient
        )
      end
      shared_recipe.update_column(:conversation_id, conversation.id)
    end
    
    # Now make it not null
    change_column_null :shared_recipes, :conversation_id, false
    add_index :shared_recipes, [:conversation_id, :created_at]
  end
  
  def down
    remove_index :shared_recipes, [:conversation_id, :created_at] if index_exists?(:shared_recipes, [:conversation_id, :created_at])
    remove_reference :shared_recipes, :conversation, foreign_key: true
  end
end
