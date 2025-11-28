class CreateCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :collections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :is_public, default: false, null: false
      t.integer :recipes_count, default: 0, null: false

      t.timestamps
    end
    
    add_index :collections, :name
    add_index :collections, :is_public
    add_index :collections, [:user_id, :name], unique: true
  end
end
