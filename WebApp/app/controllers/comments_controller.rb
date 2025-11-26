class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @recipe = Recipe.find(params[:recipe_id])
    @recipe.comments.create!(comment_params.merge(user: current_user))
    @recipe.reload # important pentru comments_count
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: recipe_path(@recipe) }
    end
  end

  def destroy
    comment = current_user.comments.find(params[:id])
    @recipe  = comment.recipe
    comment.destroy
    @recipe.reload # important pentru comments_count
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: recipe_path(@recipe) }
    end
  end

  private
  def comment_params
    params.require(:comment).permit(:body, :rating)
  end
end
