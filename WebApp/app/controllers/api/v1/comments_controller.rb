module Api
  module V1
    class CommentsController < BaseController
      skip_before_action :authenticate_api_user!, only: [ :index ]

      # GET /api/v1/recipes/:recipe_id/comments
      def index
        recipe = Recipe.find(params[:recipe_id])
        comments = recipe.comments.includes(:user).order(created_at: :desc)

        paginated = paginate(comments)
        render_success({
          comments: paginated[:items].map { |c| comment_json(c) },
          pagination: paginated[:pagination],
          average_rating: recipe.comments.where.not(rating: nil).average(:rating)&.round(1)
        })
      end

      # POST /api/v1/recipes/:recipe_id/comments
      def create
        recipe = Recipe.find(params[:recipe_id])
        comment = recipe.comments.build(comment_params)
        comment.user = current_api_user

        if comment.save
          # Update comments count
          recipe.increment!(:comments_count)

          # Create notification for recipe owner
          if recipe.user_id != current_api_user.id
            Notification.create(
              user: recipe.user,
              notification_type: "comment",
              title: "New Comment",
              message: "#{current_api_user.username} commented on your recipe '#{recipe.title}'",
              recipe_id: recipe.id
            )
          end

          render_success({ comment: comment_json(comment) }, :created)
        else
          render_error(comment.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # DELETE /api/v1/recipes/:recipe_id/comments/:id
      def destroy
        recipe = Recipe.find(params[:recipe_id])
        comment = recipe.comments.find(params[:id])

        return render_error("Not authorized", :forbidden) unless comment.user_id == current_api_user.id || current_api_user.admin?

        comment.destroy
        recipe.decrement!(:comments_count) if recipe.comments_count > 0

        render_success({ message: "Comment deleted" })
      end

      private

      def comment_params
        params.permit(:body, :rating)
      end

      def comment_json(comment)
        {
          id: comment.id,
          body: comment.body,
          rating: comment.rating,
          created_at: comment.created_at,
          user: {
            id: comment.user.id,
            username: comment.user.username,
            avatar_url: comment.user.avatar.attached? ? url_for(comment.user.avatar) : nil
          }
        }
      end
    end
  end
end




