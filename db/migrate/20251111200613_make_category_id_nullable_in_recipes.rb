class MakeCategoryIdNullableInRecipes < ActiveRecord::Migration[8.1]
  def change
    change_column_null :recipes, :category_id, true
  end
end
