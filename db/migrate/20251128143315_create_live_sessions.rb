class CreateLiveSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :live_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: true, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.datetime :scheduled_at
      t.string :status, default: 'scheduled', null: false
      t.string :stream_key
      t.string :stream_url
      t.integer :viewer_count, default: 0
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
    
    add_index :live_sessions, :status
    add_index :live_sessions, :scheduled_at
    add_index :live_sessions, [:user_id, :status]
  end
end
