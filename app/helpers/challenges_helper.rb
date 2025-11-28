# frozen_string_literal: true

module ChallengesHelper
  def calculate_user_avg_rating(user)
    return 0.0 unless user
    
    # Get average rating for each recipe
    recipes = user.recipes.includes(:comments)
    return 0.0 if recipes.empty?
    
    total_rating = 0.0
    recipes_with_ratings = 0
    
    recipes.each do |recipe|
      avg = recipe.comments.where.not(rating: nil).average(:rating)
      if avg
        total_rating += avg
        recipes_with_ratings += 1
      end
    end
    
    return 0.0 if recipes_with_ratings == 0
    (total_rating / recipes_with_ratings).round(1)
  end
end
