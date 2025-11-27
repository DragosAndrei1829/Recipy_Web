module Api
  module V1
    class FavoritesController < BaseController
      # GET /api/v1/favorites
      def index
        favorites = current_api_user.favorites
                                    .includes(recipe: [ :user, :category, :cuisine, :food_type, { photos_attachments: :blob } ])
                                    .order(created_at: :desc)

        paginated = paginate(favorites)
        render_success({
          recipes: paginated[:items].map { |f| recipe_json(f.recipe) },
          pagination: paginated[:pagination]
        })
      end

      # POST /api/v1/recipes/:recipe_id/favorite
      def create
        recipe = Recipe.find(params[:recipe_id])
        favorite = current_api_user.favorites.find_or_initialize_by(recipe: recipe)

        if favorite.new_record?
          if favorite.save
            render_success({ message: "Recipe added to favorites", favorited: true }, :created)
          else
            render_error(favorite.errors.full_messages.join(", "), :unprocessable_entity)
          end
        else
          render_success({ message: "Recipe already in favorites", favorited: true })
        end
      end

      # DELETE /api/v1/recipes/:recipe_id/favorite
      def destroy
        recipe = Recipe.find(params[:recipe_id])
        favorite = current_api_user.favorites.find_by(recipe: recipe)

        if favorite
          favorite.destroy
          render_success({ message: "Recipe removed from favorites", favorited: false })
        else
          render_success({ message: "Recipe not in favorites", favorited: false })
        end
      end

      private

      def recipe_json(recipe)
        {
          id: recipe.id,
          title: recipe.title,
          description: recipe.description,
          difficulty: recipe.difficulty,
          time_to_make: recipe.time_to_make,
          healthiness: recipe.healthiness,
          likes_count: recipe.likes_count,
          comments_count: recipe.comments_count,
          cover_photo_url: recipe.cover_photo ? url_for(recipe.cover_photo) : nil,
          created_at: recipe.created_at,
          user: {
            id: recipe.user.id,
            username: recipe.user.username,
            avatar_url: recipe.user.avatar.attached? ? url_for(recipe.user.avatar) : nil
          },
          category: recipe.category ? { id: recipe.category.id, name: recipe.category.name } : nil
        }
      end
    end
  end
end

