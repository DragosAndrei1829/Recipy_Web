class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip

    if @query.present? && @query.length >= 2
      # Search users
      @users = User.where("username ILIKE ? OR email ILIKE ?", "%#{@query}%", "%#{@query}%")
                   .limit(5)

      # Search recipes
      @recipes = Recipe.includes(:user, :category, :cuisine, :food_type)
                       .visible
                       .where("title ILIKE ? OR description ILIKE ?", "%#{@query}%", "%#{@query}%")
                       .limit(5)
    else
      @users = []
      @recipes = []
    end

    respond_to do |format|
      format.html { 
        if request.xhr? || params[:autocomplete]
          render partial: "search/autocomplete_results", locals: { users: @users, recipes: @recipes, query: @query }
        else
          render :index
        end
      }
      format.json {
        render json: {
          users: @users.map { |u| 
            { 
              id: u.id, 
              username: u.username, 
              email: u.email, 
              avatar_url: u.avatar.attached? ? (url_for(u.avatar) rescue nil) : nil,
              url: user_path(u, locale: I18n.locale)
            } 
          },
          recipes: @recipes.map { |r| 
            { 
              id: r.id, 
              title: r.title, 
              user: r.user.username,
              slug: r.slug,
              photo_url: r.photos.attached? ? (url_for(r.photos.first) rescue nil) : nil,
              url: recipe_path(r, locale: I18n.locale)
            } 
          }
        }
      }
    end
  rescue => e
    Rails.logger.error "Search error: #{e.message}"
    respond_to do |format|
      format.html { 
        if request.xhr? || params[:autocomplete]
          render partial: "search/autocomplete_results", locals: { users: [], recipes: [], query: @query }
        else
          render :index
        end
      }
      format.json { render json: { users: [], recipes: [] } }
    end
  end
end
