module Api
  module V1
    class LikesController < BaseController
      # POST /api/v1/recipes/:recipe_id/like
      def create
        recipe = Recipe.find(params[:recipe_id])
        like = current_api_user.likes.find_or_initialize_by(recipe: recipe)

        if like.new_record?
          if like.save
            # Update likes count
            recipe.increment!(:likes_count)

            # Create notification for recipe owner
            if recipe.user_id != current_api_user.id
              Notification.create(
                user: recipe.user,
                notification_type: "like",
                title: "New Like",
                message: "#{current_api_user.username} liked your recipe '#{recipe.title}'",
                recipe_id: recipe.id
              )
            end

            render_success({
              message: "Recipe liked",
              liked: true,
              likes_count: recipe.reload.likes_count
            }, :created)
          else
            render_error(like.errors.full_messages.join(", "), :unprocessable_entity)
          end
        else
          render_success({
            message: "Recipe already liked",
            liked: true,
            likes_count: recipe.likes_count
          })
        end
      end

      # DELETE /api/v1/recipes/:recipe_id/like
      def destroy
        recipe = Recipe.find(params[:recipe_id])
        like = current_api_user.likes.find_by(recipe: recipe)

        if like
          like.destroy
          recipe.decrement!(:likes_count) if recipe.likes_count > 0

          render_success({
            message: "Recipe unliked",
            liked: false,
            likes_count: recipe.reload.likes_count
          })
        else
          render_success({
            message: "Recipe not liked",
            liked: false,
            likes_count: recipe.likes_count
          })
        end
      end
    end
  end
end

