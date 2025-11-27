class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.text :description
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :invite_code, null: false
      t.boolean :is_private, default: true, null: false
      t.integer :members_count, default: 0, null: false
      t.integer :recipes_count, default: 0, null: false

      t.timestamps
    end

    add_index :groups, :invite_code, unique: true
    add_index :groups, :name
  end
end
