module Api
  module V1
    class RecipesController < BaseController
      skip_before_action :authenticate_api_user!, only: [ :index, :show, :top, :search ]
      before_action :set_recipe, only: [ :show, :update, :destroy ]

      # GET /api/v1/recipes
      def index
        recipes = Recipe.visible.includes(:user, :category, :cuisine, :food_type, photos_attachments: :blob)
                        .order(created_at: :desc)

        # Apply filters
        recipes = apply_filters(recipes)

        paginated = paginate(recipes)
        render_success({
          recipes: paginated[:items].map { |r| recipe_json(r) },
          pagination: paginated[:pagination]
        })
      end

      # GET /api/v1/recipes/feed
      def feed
        # Get IDs of users being followed + current user
        followed_user_ids = current_api_user.following.pluck(:id)
        followed_user_ids << current_api_user.id

        recipes = Recipe.visible.includes(:user, :category, :cuisine, :food_type, photos_attachments: :blob)
                        .where(user_id: followed_user_ids)
                        .order(created_at: :desc)

        # If fewer than 10 recipes, add recommended
        if recipes.count < 10
          recommended_ids = Recipe.visible.top_of_month(20).pluck(:id)
          all_ids = recipes.pluck(:id) + (recommended_ids - recipes.pluck(:id))
          recipes = Recipe.visible.includes(:user, :category, :cuisine, :food_type, photos_attachments: :blob)
                          .where(id: all_ids)
                          .order(created_at: :desc)
        end

        paginated = paginate(recipes)
        render_success({
          recipes: paginated[:items].map { |r| recipe_json(r) },
          pagination: paginated[:pagination]
        })
      end

      # GET /api/v1/recipes/top
      def top
        period = params[:period] || "day"

        recipes = case period
        when "day" then Recipe.created_today
        when "week" then Recipe.created_this_week
        when "month" then Recipe.created_this_month
        when "year" then Recipe.created_this_year
        else Recipe.created_today
        end

        recipes = recipes.includes(:user, :category, :cuisine, :food_type, photos_attachments: :blob)
                         .top_by_likes

        paginated = paginate(recipes)
        render_success({
          recipes: paginated[:items].map { |r| recipe_json(r) },
          pagination: paginated[:pagination],
          period: period
        })
      end

      # GET /api/v1/recipes/search
      def search
        query = params[:q].to_s.strip
        return render_error("Search query is required", :bad_request) if query.blank?

        recipes = Recipe.includes(:user, :category, :cuisine, :food_type, photos_attachments: :blob)
                        .where("title ILIKE ? OR ingredients ILIKE ?", "%#{query}%", "%#{query}%")
                        .order(created_at: :desc)

        recipes = apply_filters(recipes)

        paginated = paginate(recipes)
        render_success({
          recipes: paginated[:items].map { |r| recipe_json(r) },
          pagination: paginated[:pagination],
          query: query
        })
      end

      # GET /api/v1/recipes/:id
      def show
        render_success({
          recipe: recipe_json(@recipe, full: true)
        })
      end

      # POST /api/v1/recipes
      def create
        recipe = current_api_user.recipes.build(recipe_params)

        if recipe.save
          render_success({ recipe: recipe_json(recipe, full: true) }, :created)
        else
          render_error(recipe.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # PUT /api/v1/recipes/:id
      def update
        return render_error("Not authorized", :forbidden) unless @recipe.user_id == current_api_user.id

        if @recipe.update(recipe_params)
          render_success({ recipe: recipe_json(@recipe.reload, full: true) })
        else
          render_error(@recipe.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # DELETE /api/v1/recipes/:id
      def destroy
        return render_error("Not authorized", :forbidden) unless @recipe.user_id == current_api_user.id || current_api_user.admin?

        @recipe.destroy
        render_success({ message: "Recipe deleted successfully" })
      end

      private

      def set_recipe
        @recipe = Recipe.includes(:user, :category, :cuisine, :food_type, :comments, photos_attachments: :blob)
                        .find(params[:id])
      end

      def recipe_params
        params.permit(
          :title, :description, :ingredients, :preparation,
          :category_id, :cuisine_id, :food_type_id,
          :difficulty, :time_to_make, :healthiness,
          photos: [],
          nutrition: [ :calories, :sugar, :protein, :fat, :carbs ]
        )
      end

      def apply_filters(recipes)
        # Category filter
        recipes = recipes.where(category_id: params[:category_id]) if params[:category_id].present?

        # Cuisine filter
        recipes = recipes.where(cuisine_id: params[:cuisine_id]) if params[:cuisine_id].present?

        # Food type filter
        recipes = recipes.where(food_type_id: params[:food_type_id]) if params[:food_type_id].present?

        # Max calories
        if params[:max_calories].present?
          recipes = recipes.where("(nutrition->>'calories')::int <= ?", params[:max_calories].to_i)
        end

        # Max time
        if params[:max_time].present?
          recipes = recipes.where("time_to_make > 0 AND time_to_make <= ?", params[:max_time].to_i)
        end

        # Min difficulty
        if params[:min_difficulty].present?
          recipes = recipes.where("difficulty >= ?", params[:min_difficulty].to_i)
        end

        # Min healthiness
        if params[:min_healthiness].present?
          recipes = recipes.where("healthiness >= ?", params[:min_healthiness].to_i)
        end

        # Min rating
        if params[:min_rating].present?
          rating_sql = <<~SQL
            COALESCE(
              (SELECT AVG(comments.rating)
               FROM comments
               WHERE comments.recipe_id = recipes.id
                 AND comments.rating IS NOT NULL),
              0
            ) >= ?
          SQL
          recipes = recipes.where(rating_sql, params[:min_rating].to_f)
        end

        recipes
      end

      def recipe_json(recipe, full: false)
        data = {
          id: recipe.id,
          title: recipe.title,
          description: recipe.description,
          difficulty: recipe.difficulty,
          time_to_make: recipe.time_to_make,
          healthiness: recipe.healthiness,
          likes_count: recipe.likes_count,
          comments_count: recipe.comments_count,
          nutrition: recipe.nutrition,
          created_at: recipe.created_at,
          updated_at: recipe.updated_at,
          user: {
            id: recipe.user.id,
            username: recipe.user.username,
            avatar_url: recipe.user.avatar.attached? ? url_for(recipe.user.avatar) : nil
          },
          category: recipe.category ? { id: recipe.category.id, name: recipe.category.name } : nil,
          cuisine: recipe.cuisine ? { id: recipe.cuisine.id, name: recipe.cuisine.name } : nil,
          food_type: recipe.food_type ? { id: recipe.food_type.id, name: recipe.food_type.name } : nil,
          cover_photo_url: recipe.cover_photo ? url_for(recipe.cover_photo) : nil,
          photos: recipe.photos.map { |p| { id: p.id, url: url_for(p) } }
        }

        if full
          data.merge!({
            ingredients: recipe.ingredients,
            preparation: recipe.preparation,
            is_liked: current_api_user ? recipe.likes.exists?(user_id: current_api_user.id) : false,
            is_favorited: current_api_user ? recipe.favorites.exists?(user_id: current_api_user.id) : false,
            average_rating: recipe.comments.where.not(rating: nil).average(:rating)&.round(1),
            comments: recipe.comments.includes(:user).order(created_at: :desc).limit(10).map do |c|
              {
                id: c.id,
                body: c.body,
                rating: c.rating,
                created_at: c.created_at,
                user: {
                  id: c.user.id,
                  username: c.user.username,
                  avatar_url: c.user.avatar.attached? ? url_for(c.user.avatar) : nil
                }
              }
            end
          })
        end

        data
      end
    end
  end
end

