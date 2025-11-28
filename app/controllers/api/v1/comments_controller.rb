module Api
  module V1
    class CommentsController < BaseController
      skip_before_action :authenticate_api_user!, only: [ :index ]

      # GET /api/v1/recipes/:recipe_id/comments
      def index
        recipe = Recipe.find(params[:recipe_id])
        comments = recipe.comments.includes(:user).order(created_at: :desc)

        paginated = paginate(comments)
        # Support sorting
        sort_by = params[:sort] || 'recent'
        sorted_comments = case sort_by
                         when 'helpful'
                           comments.order(helpful_count: :desc, created_at: :desc)
                         when 'highest'
                           comments.order(rating: :desc, created_at: :desc)
                         else
                           comments.order(created_at: :desc)
                         end

        paginated = paginate(sorted_comments)
        
        render_success({
          comments: paginated[:items].map { |c| comment_json(c) },
          pagination: paginated[:pagination],
          average_rating: recipe.comments.where.not(rating: nil).average(:rating)&.round(1),
          average_taste_rating: recipe.average_taste_rating,
          average_difficulty_rating: recipe.average_difficulty_rating,
          average_time_rating: recipe.average_time_rating,
          average_cost_rating: recipe.average_cost_rating
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
        
        # Update average rating
        recipe.update_average_rating if comment.rating.present?

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

      # POST /api/v1/recipes/:recipe_id/comments/:id/toggle_helpful
      def toggle_helpful
        recipe = Recipe.find(params[:recipe_id])
        comment = recipe.comments.find(params[:id])
        helpful = comment.review_helpfuls.find_by(user: current_api_user)

        if helpful
          helpful.destroy
          action = "removed"
        else
          comment.review_helpfuls.create!(user: current_api_user)
          action = "added"
        end

        comment.reload

        render_success({
          action: action,
          helpful_count: comment.helpful_count,
          is_helpful: comment.helpful_by?(current_api_user)
        })
      end

      private

      def comment_params
        params.permit(:body, :rating, :taste_rating, :difficulty_rating, :time_rating, :cost_rating)
      end

      def comment_json(comment)
        {
          id: comment.id,
          body: comment.body,
          rating: comment.rating,
          taste_rating: comment.taste_rating,
          difficulty_rating: comment.difficulty_rating,
          time_rating: comment.time_rating,
          cost_rating: comment.cost_rating,
          helpful_count: comment.helpful_count,
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

