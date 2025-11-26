class LikesController < ApplicationController
  before_action :authenticate_user!

  def create
    @recipe = Recipe.find(params[:recipe_id])
    current_user.likes.find_or_create_by!(recipe: @recipe)
    # Reload with associations to get fresh like state
    @recipe = Recipe.includes(:user, :category, :cuisine, :food_type, likes: :user).find(params[:recipe_id])
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: recipe_path(@recipe) }
    end
  end

  def destroy
    @recipe = Recipe.find(params[:recipe_id])
    current_user.likes.where(recipe: @recipe).destroy_all
    # Reload with associations to get fresh like state
    @recipe = Recipe.includes(:user, :category, :cuisine, :food_type, likes: :user).find(params[:recipe_id])
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: recipe_path(@recipe) }
    end
  end
end
