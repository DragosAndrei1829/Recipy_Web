class CreateMealPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.string :meal_type, null: false, default: "dinner" # breakfast, lunch, dinner, snack
      t.date :planned_for, null: false
      t.text :notes
      t.integer :servings, default: 1, null: false

      t.timestamps
    end
    
    add_index :meal_plans, [:user_id, :planned_for]
    add_index :meal_plans, :planned_for
    add_index :meal_plans, :meal_type
  end
end
