class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [ :create, :destroy ]

  def index
    @favorites = current_user.favorite_recipes.includes(:user, :category, :cuisine, :food_type)
                             .order(created_at: :desc)
  end

  def create
    @favorite = current_user.favorites.find_or_initialize_by(recipe: @recipe)

    respond_to do |format|
      if @favorite.save
        format.turbo_stream
        format.html { redirect_to @recipe, notice: t("favorites.added") }
      else
        format.html { redirect_to @recipe, alert: t("favorites.error") }
      end
    end
  end

  def destroy
    @favorite = current_user.favorites.find_by(recipe: @recipe)

    respond_to do |format|
      if @favorite&.destroy
        format.turbo_stream
        format.html { redirect_to @recipe, notice: t("favorites.removed") }
      else
        format.html { redirect_to @recipe, alert: t("favorites.error") }
      end
    end
  end

  private

  def set_recipe
    @recipe = Recipe.find_by(slug: params[:recipe_id]) || Recipe.find(params[:recipe_id])
  end
end
