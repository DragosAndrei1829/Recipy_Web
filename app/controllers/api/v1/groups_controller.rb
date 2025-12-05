# frozen_string_literal: true

module Api
  module V1
    class GroupsController < BaseController
      before_action :authenticate_user!
      before_action :set_group, only: [:show, :update, :destroy, :members, :recipes, :add_recipe, :remove_recipe, :leave, :messages, :send_message]
      before_action :authorize_member!, only: [:show, :recipes, :messages, :send_message, :leave]
      before_action :authorize_admin!, only: [:update, :destroy, :members]

      # GET /api/v1/groups
      # List user's groups
      def index
        groups = current_user.groups.includes(:owner).order(created_at: :desc)

        render_success(groups: groups.map { |g| group_json(g) })
      end

      # GET /api/v1/groups/:id
      # Show group details
      def show
        render_success(group: group_json(@group, include_invite_code: @group.admin?(current_user)))
      end

      # POST /api/v1/groups
      # Create a new group
      def create
        group = current_user.owned_groups.build(group_params)

        if group.save
          render_success({ group: group_json(group, include_invite_code: true) }, :created)
        else
          render_error(group.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # PUT /api/v1/groups/:id
      # Update group
      def update
        if @group.update(group_params)
          render_success(group: group_json(@group, include_invite_code: true))
        else
          render_error(@group.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # DELETE /api/v1/groups/:id
      # Delete group
      def destroy
        @group.destroy
        render_success(message: "Group deleted")
      end

      # POST /api/v1/groups/join
      # Join group by invite code
      def join
        result = Group.join_by_invite_code(params[:invite_code], current_user)

        if result[:success]
          render_success(group: group_json(result[:group]))
        else
          render_error(result[:error], :unprocessable_entity)
        end
      end

      # DELETE /api/v1/groups/:id/leave
      # Leave group
      def leave
        if @group.owner == current_user
          render_error("Nu poți părăsi grupul pe care l-ai creat", :forbidden)
        elsif @group.remove_member(current_user)
          render_success(message: "Ai părăsit grupul")
        else
          render_error("A apărut o eroare", :unprocessable_entity)
        end
      end

      # GET /api/v1/groups/:id/members
      # List group members
      def members
        members = @group.group_memberships.includes(:user).order(role: :asc, joined_at: :desc)

        render_success(members: members.map { |m| membership_json(m) })
      end

      # GET /api/v1/groups/:id/recipes
      # List group recipes
      def recipes
        group_recipes = @group.group_recipes.includes(recipe: [:user, :category, :cuisine]).order(created_at: :desc)

        render_success(recipes: group_recipes.map { |gr| group_recipe_json(gr) })
      end

      # POST /api/v1/groups/:id/recipes
      # Add recipe to group
      def add_recipe
        recipe = Recipe.find(params[:recipe_id])

        if @group.add_recipe(recipe, added_by: current_user, note: params[:note])
          render_success(message: "Rețeta a fost adăugată")
        else
          render_error("Rețeta este deja în grup sau nu ai permisiunea", :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotFound
        render_error("Rețeta nu a fost găsită", :not_found)
      end

      # DELETE /api/v1/groups/:id/recipes/:recipe_id
      # Remove recipe from group
      def remove_recipe
        recipe = Recipe.find(params[:recipe_id])

        if @group.remove_recipe(recipe, removed_by: current_user)
          render_success(message: "Rețeta a fost eliminată")
        else
          render_error("Nu ai permisiunea de a elimina această rețetă", :forbidden)
        end
      rescue ActiveRecord::RecordNotFound
        render_error("Rețeta nu a fost găsită", :not_found)
      end

      # GET /api/v1/groups/:id/messages
      # Get group messages
      def messages
        messages = @group.group_messages
                         .includes(:user)
                         .order(created_at: :desc)
                         .limit(params[:limit] || 50)
                         .reverse

        render_success(messages: messages.map { |m| message_json(m) })
      end

      # POST /api/v1/groups/:id/messages
      # Send message in group
      def send_message
        message = @group.group_messages.build(user: current_user, content: params[:content])

        if message.save
          render_success(message: message_json(message))
        else
          render_error(message.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      private

      def set_group
        @group = Group.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Grupul nu a fost găsit", :not_found)
      end

      def group_params
        params.permit(:name, :description, :is_private, :cover_image)
      end

      def authorize_member!
        unless @group.viewable_by?(current_user)
          render_error("Nu ai acces la acest grup", :forbidden)
        end
      end

      def authorize_admin!
        unless @group.admin?(current_user)
          render_error("Nu ai permisiunea de a face această acțiune", :forbidden)
        end
      end

      def group_json(group, include_invite_code: false)
        json = {
          id: group.id,
          name: group.name,
          description: group.description,
          is_private: group.is_private,
          members_count: group.members_count,
          recipes_count: group.recipes_count,
          owner: {
            id: group.owner.id,
            username: group.owner.username,
            avatar_url: group.owner.avatar.attached? ? url_for(group.owner.avatar) : nil
          },
          cover_image_url: group.cover_image.attached? ? url_for(group.cover_image) : nil,
          is_member: group.member?(current_user),
          is_admin: group.admin?(current_user),
          created_at: group.created_at.iso8601
        }

        json[:invite_code] = group.invite_code if include_invite_code

        json
      end

      def membership_json(membership)
        {
          id: membership.id,
          user: {
            id: membership.user.id,
            username: membership.user.username,
            avatar_url: membership.user.avatar.attached? ? url_for(membership.user.avatar) : nil
          },
          role: membership.role,
          joined_at: membership.joined_at&.iso8601 || membership.created_at.iso8601
        }
      end

      def group_recipe_json(group_recipe)
        recipe = group_recipe.recipe
        {
          id: group_recipe.id,
          recipe: {
            id: recipe.id,
            title: recipe.title,
            description: recipe.description&.truncate(100),
            time_to_make: recipe.time_to_make,
            difficulty: recipe.difficulty,
            likes_count: recipe.likes_count,
            cover_image_url: recipe.cover_photo&.attached? ? url_for(recipe.cover_photo) : nil,
            user: {
              id: recipe.user.id,
              username: recipe.user.username
            }
          },
          note: group_recipe.note,
          added_by: {
            id: group_recipe.added_by.id,
            username: group_recipe.added_by.username
          },
          added_at: group_recipe.created_at.iso8601
        }
      end

      def message_json(message)
        {
          id: message.id,
          content: message.content,
          user: {
            id: message.user.id,
            username: message.user.username,
            avatar_url: message.user.avatar.attached? ? url_for(message.user.avatar) : nil
          },
          created_at: message.created_at.iso8601
        }
      end
    end
  end
end




