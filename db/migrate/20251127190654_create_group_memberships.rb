class CreateGroupMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, default: 'member', null: false
      t.datetime :joined_at, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    # Ensure a user can only be in a group once
    add_index :group_memberships, [:group_id, :user_id], unique: true
    add_index :group_memberships, :role
  end
end
