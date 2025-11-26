class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.boolean :read, default: false, null: false

      t.timestamps
    end

    add_index :messages, [ :conversation_id, :created_at ]
    add_index :messages, :read
  end
end
