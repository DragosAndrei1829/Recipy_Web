class CreateVideoTimestamps < ActiveRecord::Migration[8.1]
  def change
    create_table :video_timestamps do |t|
      t.references :recipe, null: false, foreign_key: true
      t.integer :step_number, null: false
      t.integer :timestamp_seconds, null: false
      t.string :title, null: false
      t.text :description
      t.integer :position

      t.timestamps
    end
    
    add_index :video_timestamps, [:recipe_id, :step_number], unique: true
    add_index :video_timestamps, [:recipe_id, :position]
  end
end
