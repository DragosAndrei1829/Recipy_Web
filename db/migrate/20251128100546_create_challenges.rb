class CreateChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :challenges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :challenge_type, null: false, default: "recipe" # recipe, cooking_technique, ingredient, etc.
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, null: false, default: "upcoming" # upcoming, active, completed, cancelled
      t.text :rules
      t.text :prize
      t.integer :participants_count, default: 0, null: false
      t.integer :submissions_count, default: 0, null: false

      t.timestamps
    end
    
    add_index :challenges, :status
    add_index :challenges, :challenge_type
    add_index :challenges, [:start_date, :end_date]
  end
end
