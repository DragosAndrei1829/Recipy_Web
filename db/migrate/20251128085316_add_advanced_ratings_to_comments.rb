class AddAdvancedRatingsToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :taste_rating, :integer, default: 0
    add_column :comments, :difficulty_rating, :integer, default: 0
    add_column :comments, :time_rating, :integer, default: 0
    add_column :comments, :cost_rating, :integer, default: 0
    add_column :comments, :helpful_count, :integer, default: 0, null: false
    
    add_index :comments, :taste_rating
    add_index :comments, :difficulty_rating
    add_index :comments, :time_rating
    add_index :comments, :cost_rating
  end
end
