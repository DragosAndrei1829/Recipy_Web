class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip

    if @query.present?
      # Search users
      @users = User.where("username ILIKE ? OR email ILIKE ?", "%#{@query}%", "%#{@query}%")
                   .limit(5)

      # Search recipes
      @recipes = Recipe.includes(:user, :category, :cuisine, :food_type)
                       .where("title ILIKE ? OR description ILIKE ?", "%#{@query}%", "%#{@query}%")
                       .limit(5)
    else
      @users = []
      @recipes = []
    end

    respond_to do |format|
      format.html { render partial: "search/results", locals: { users: @users, recipes: @recipes, query: @query } }
      format.json {
        render json: {
          users: @users.map { |u| { id: u.id, username: u.username, email: u.email, avatar_url: u.avatar.attached? ? url_for(u.avatar.variant(resize_to_fill: [ 40, 40 ])) : nil } },
          recipes: @recipes.map { |r| { id: r.id, title: r.title, user: r.user.username, photo_url: r.photos.attached? ? url_for(r.photos.first.variant(resize_to_fill: [ 60, 60 ])) : nil } }
        }
      }
    end
  rescue => e
    respond_to do |format|
      format.html { render partial: "search/results", locals: { users: [], recipes: [], query: @query } }
      format.json { render json: { users: [], recipes: [] } }
    end
  end
end
