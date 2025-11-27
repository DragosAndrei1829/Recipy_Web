class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @recipe = Recipe.find(params[:recipe_id])
    # Support both :body (from show page) and :content (from feed inline form)
    body_content = params.dig(:comment, :body) || params.dig(:comment, :content) || params[:content]
    @comment = @recipe.comments.create!(body: body_content, user: current_user)
    @recipe.reload # important pentru comments_count
    
    # Check if this is from inline feed or show page
    @from_feed = request.referer&.include?('/recipes') && !request.referer&.include?("/recipes/#{@recipe.id}")
    
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
    params.require(:comment).permit(:body, :content, :rating)
  end
end
