class AddMetaToRecipes < ActiveRecord::Migration[8.1]
  def change
  #add_reference :recipes, :category, foreign_key: true, null: true
  add_reference :recipes, :cuisine, foreign_key: true, null: true
  add_reference :recipes, :food_type, foreign_key: true, null: true
  add_column :recipes, :cover_photo_id, :bigint
  add_column :recipes, :photos_order, :json
  add_column :recipes, :nutrition, :json
  end

end
