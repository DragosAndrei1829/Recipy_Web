module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_api_user!, only: [ :show, :search ]
      before_action :set_user, only: [ :show, :recipes, :followers, :following, :follow, :unfollow ]

      # GET /api/v1/users/search
      def search
        query = params[:q].to_s.strip
        return render_error("Search query is required", :bad_request) if query.blank?

        users = User.where("username ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%")
                    .order(:username)
                    .limit(20)

        render_success({
          users: users.map { |u| user_json(u) }
        })
      end

      # GET /api/v1/users/:id
      def show
        render_success({ user: user_json(@user, full: true) })
      end

      # GET /api/v1/users/:id/recipes
      def recipes
        recipes = @user.recipes.includes(:category, :cuisine, :food_type, photos_attachments: :blob)
                       .order(created_at: :desc)

        paginated = paginate(recipes)
        render_success({
          recipes: paginated[:items].map { |r| recipe_summary_json(r) },
          pagination: paginated[:pagination]
        })
      end

      # GET /api/v1/users/:id/followers
      def followers
        followers = @user.followers.includes(avatar_attachment: :blob)

        paginated = paginate(followers)
        render_success({
          users: paginated[:items].map { |u| user_json(u) },
          pagination: paginated[:pagination]
        })
      end

      # GET /api/v1/users/:id/following
      def following
        following = @user.following.includes(avatar_attachment: :blob)

        paginated = paginate(following)
        render_success({
          users: paginated[:items].map { |u| user_json(u) },
          pagination: paginated[:pagination]
        })
      end

      # POST /api/v1/users/:id/follow
      def follow
        return render_error("Cannot follow yourself", :unprocessable_entity) if @user.id == current_api_user.id

        follow = current_api_user.follows.find_or_initialize_by(user: @user)

        if follow.new_record?
          if follow.save
            # Create notification
            Notification.create(
              user: @user,
              notification_type: "follow",
              title: "New Follower",
              message: "#{current_api_user.username} started following you"
            )
            render_success({ message: "Now following #{@user.username}", following: true })
          else
            render_error(follow.errors.full_messages.join(", "), :unprocessable_entity)
          end
        else
          render_success({ message: "Already following #{@user.username}", following: true })
        end
      end

      # DELETE /api/v1/users/:id/follow
      def unfollow
        follow = current_api_user.follows.find_by(user: @user)

        if follow
          follow.destroy
          render_success({ message: "Unfollowed #{@user.username}", following: false })
        else
          render_success({ message: "Not following #{@user.username}", following: false })
        end
      end

      # GET /api/v1/users/profile
      def profile
        render_success({ user: user_json(current_api_user, full: true) })
      end

      # PUT/PATCH /api/v1/users/profile
      def update_profile
        if current_api_user.update(profile_params)
          render_success({ user: user_json(current_api_user.reload, full: true) })
        else
          render_error(current_api_user.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # POST /api/v1/users/avatar
      def update_avatar
        if params[:avatar].present?
          current_api_user.avatar.attach(params[:avatar])
          render_success({
            message: "Avatar updated successfully",
            avatar_url: url_for(current_api_user.avatar)
          })
        else
          render_error("No avatar provided", :bad_request)
        end
      end

      # DELETE /api/v1/users/avatar
      def delete_avatar
        if current_api_user.avatar.attached?
          current_api_user.avatar.purge
          render_success({ message: "Avatar removed successfully" })
        else
          render_error("No avatar to remove", :bad_request)
        end
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def profile_params
        params.permit(:username, :first_name, :last_name, :phone)
      end

      def user_json(user, full: false)
        data = {
          id: user.id,
          username: user.username,
          avatar_url: user.avatar.attached? ? url_for(user.avatar) : nil,
          recipes_count: user.recipes.count,
          followers_count: user.followers.count,
          following_count: user.following.count
        }

        if full
          # Only include email if user is viewing their own profile
          email_data = {}
          if current_api_user && current_api_user.id == user.id
            email_data[:email] = user.email
          end
          
          data.merge!({
            first_name: user.first_name,
            last_name: user.last_name,
            created_at: user.created_at,
            is_following: current_api_user ? current_api_user.following.exists?(user.id) : false,
            is_followed_by: current_api_user ? current_api_user.followers.exists?(user.id) : false
          }.merge(email_data))
        end

        data
      end

      def recipe_summary_json(recipe)
        {
          id: recipe.id,
          title: recipe.title,
          description: recipe.description,
          difficulty: recipe.difficulty,
          time_to_make: recipe.time_to_make,
          likes_count: recipe.likes_count,
          comments_count: recipe.comments_count,
          cover_photo_url: recipe.cover_photo ? url_for(recipe.cover_photo) : nil,
          created_at: recipe.created_at
        }
      end
    end
  end
end

