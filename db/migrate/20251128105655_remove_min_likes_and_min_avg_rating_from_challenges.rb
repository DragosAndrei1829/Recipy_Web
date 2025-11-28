class RemoveMinLikesAndMinAvgRatingFromChallenges < ActiveRecord::Migration[8.1]
  def change
    remove_column :challenges, :min_likes, :integer
    remove_column :challenges, :min_avg_rating, :decimal
  end
end
