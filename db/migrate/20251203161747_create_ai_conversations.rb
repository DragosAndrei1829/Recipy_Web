class CreateAiConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :provider
      t.json :messages
      t.datetime :last_message_at

      t.timestamps
    end
  end
end
