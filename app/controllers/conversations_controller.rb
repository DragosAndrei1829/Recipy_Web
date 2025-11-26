class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversations = current_user.conversations
                                  .includes(:sender, :recipient, messages: { images_attachments: :blob })
                                  .order(updated_at: :desc)
  end

  def show
    @conversation = Conversation.find(params[:id])
    unless @conversation.sender == current_user || @conversation.recipient == current_user
      redirect_to conversations_path, alert: t("conversations.unauthorized")
      return
    end
    @full_screen_chat = true

    @other_user = @conversation.other_user(current_user)
    @messages = @conversation.messages.includes(:user).order(created_at: :asc)
    @shared_recipes = @conversation.shared_recipes.includes(:recipe, :sender).order(created_at: :asc)

    # Combine messages and shared recipes, sorted by created_at
    @conversation_items = []
    @messages.each { |m| @conversation_items << { type: :message, item: m, created_at: m.created_at } }
    @shared_recipes.each { |sr| @conversation_items << { type: :shared_recipe, item: sr, created_at: sr.created_at } }
    @conversation_items.sort_by! { |i| i[:created_at] }

    # Mark messages as read
    @conversation.messages.where.not(user: current_user).update_all(read: true)
    # Mark shared recipes as read
    @conversation.shared_recipes.where.not(sender: current_user).update_all(read: true)
  end

  def create
    recipient = User.find(params[:recipient_id])

    # Find or create conversation
    @conversation = Conversation.between(current_user, recipient).first
    unless @conversation
      @conversation = Conversation.create!(
        sender: current_user,
        recipient: recipient
      )
    end

    redirect_to conversation_path(@conversation)
  end
end
