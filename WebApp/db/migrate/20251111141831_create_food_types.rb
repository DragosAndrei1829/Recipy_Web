class CreateFoodTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :food_types do |t|
      t.string :name

      t.timestamps
    end
    add_index :food_types, :name
  end
end
