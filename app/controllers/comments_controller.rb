class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: [:destroy, :toggle_helpful]

  def create
    @recipe = Recipe.find_by(slug: params[:recipe_id]) || Recipe.find(params[:recipe_id])
    # Support both :body (from show page) and :content (from feed inline form)
    body_content = params.dig(:comment, :body) || params.dig(:comment, :content) || params[:content] || params[:body]
    
    comment_attributes = {
      body: body_content,
      user: current_user,
      rating: params.dig(:comment, :rating),
      taste_rating: params.dig(:comment, :taste_rating),
      difficulty_rating: params.dig(:comment, :difficulty_rating),
      time_rating: params.dig(:comment, :time_rating),
      cost_rating: params.dig(:comment, :cost_rating)
    }.compact
    
    @comment = @recipe.comments.create!(comment_attributes)
    @recipe.reload # important pentru comments_count
    @recipe.update_average_rating if @comment.rating.present?
    
    # Check if this is from inline feed or show page
    @from_feed = request.referer&.include?('/recipes') && !request.referer&.include?("/recipes/#{@recipe.slug}")
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: recipe_path(@recipe) }
      format.json { render json: @comment, status: :created }
    end
  end

  def destroy
    @recipe = @comment.recipe
    @comment.destroy
    @recipe.reload # important pentru comments_count
    @recipe.update_average_rating
    
    # Check if this is from inline feed or show page
    @from_feed = request.referer&.include?('/recipes') && !request.referer&.include?("/recipes/#{@recipe.slug}")
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: recipe_path(@recipe) }
      format.json { head :no_content }
    end
  end

  def toggle_helpful
    @recipe = @comment.recipe
    helpful = @comment.review_helpfuls.find_by(user: current_user)
    
    if helpful
      helpful.destroy
      action = "removed"
    else
      @comment.review_helpfuls.create!(user: current_user)
      action = "added"
    end
    
    @comment.reload
    
    respond_to do |format|
      format.turbo_stream
      format.json { render json: { action: action, helpful_count: @comment.helpful_count } }
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body, :content, :rating, :taste_rating, :difficulty_rating, :time_rating, :cost_rating)
  end
end
