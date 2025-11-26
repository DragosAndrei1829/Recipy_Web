module Api
  module V1
    class ConversationsController < BaseController
      before_action :set_conversation, only: [ :show, :messages ]

      # GET /api/v1/conversations
      def index
        conversations = current_api_user.conversations
                                        .includes(:sender, :recipient, messages: :user)
                                        .order(updated_at: :desc)

        render_success({
          conversations: conversations.map { |c| conversation_json(c) },
          unread_count: current_api_user.unread_messages_count
        })
      end

      # GET /api/v1/conversations/:id
      def show
        render_success({ conversation: conversation_json(@conversation, full: true) })
      end

      # POST /api/v1/conversations
      def create
        recipient = User.find(params[:recipient_id])

        return render_error("Cannot message yourself", :unprocessable_entity) if recipient.id == current_api_user.id

        # Find existing conversation or create new one
        conversation = Conversation.between(current_api_user, recipient).first

        if conversation.nil?
          conversation = Conversation.create!(sender: current_api_user, recipient: recipient)
        end

        render_success({ conversation: conversation_json(conversation) }, :created)
      end

      # GET /api/v1/conversations/:id/messages
      def messages
        messages = @conversation.messages.includes(:user).order(created_at: :desc)

        # Mark messages as read
        @conversation.messages.where.not(user: current_api_user).where(read: false).update_all(read: true)

        paginated = paginate(messages)
        render_success({
          messages: paginated[:items].reverse.map { |m| message_json(m) },
          pagination: paginated[:pagination]
        })
      end

      # POST /api/v1/conversations/:id/messages
      def create_message
        conversation = current_api_user.conversations.find(params[:id])

        message = conversation.messages.build(message_params)
        message.user = current_api_user

        if message.save
          conversation.touch # Update conversation timestamp

          # Create notification for recipient
          recipient = conversation.other_user(current_api_user)
          Notification.create(
            user: recipient,
            notification_type: "message",
            title: "New Message",
            message: "#{current_api_user.username} sent you a message"
          )

          render_success({ message: message_json(message) }, :created)
        else
          render_error(message.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      private

      def set_conversation
        @conversation = current_api_user.conversations.find(params[:id])
      end

      def message_params
        params.permit(:body, :recipe_id)
      end

      def conversation_json(conversation, full: false)
        other_user = conversation.other_user(current_api_user)
        last_message = conversation.messages.order(created_at: :desc).first

        data = {
          id: conversation.id,
          other_user: {
            id: other_user.id,
            username: other_user.username,
            avatar_url: other_user.avatar.attached? ? url_for(other_user.avatar) : nil
          },
          last_message: last_message ? {
            body: last_message.body.truncate(50),
            created_at: last_message.created_at,
            is_mine: last_message.user_id == current_api_user.id
          } : nil,
          unread_count: conversation.unread_messages_count_for(current_api_user),
          updated_at: conversation.updated_at
        }

        if full
          data[:messages] = conversation.messages.includes(:user).order(created_at: :asc).limit(50).map { |m| message_json(m) }
        end

        data
      end

      def message_json(message)
        data = {
          id: message.id,
          body: message.body,
          read: message.read,
          is_mine: message.user_id == current_api_user.id,
          created_at: message.created_at,
          user: {
            id: message.user.id,
            username: message.user.username,
            avatar_url: message.user.avatar.attached? ? url_for(message.user.avatar) : nil
          }
        }

        if message.recipe_id.present?
          recipe = Recipe.find_by(id: message.recipe_id)
          if recipe
            data[:shared_recipe] = {
              id: recipe.id,
              title: recipe.title,
              cover_photo_url: recipe.cover_photo ? url_for(recipe.cover_photo) : nil
            }
          end
        end

        data
      end
    end
  end
end

