# frozen_string_literal: true

module Api
  module V1
    class AiAssistantController < BaseController
      before_action :authenticate_user!

      # POST /api/v1/ai/chat
      # Send a message to the AI assistant
      def chat
        message = params[:message]&.strip
        conversation_id = params[:conversation_id]

        return render_error("Message is required", :bad_request) if message.blank?

        # Initialize AI assistant
        assistant = AiRecipeAssistant.new(user: current_user)

        # Get conversation history (could be stored in Redis/DB for persistence)
        conversation_history = get_conversation_history(conversation_id)

        # Get AI response
        response = assistant.chat(message, conversation_history: conversation_history)

        # Store conversation
        new_conversation_id = store_conversation(conversation_id, message, response)

        render_success({
          conversation_id: new_conversation_id,
          response: response,
          timestamp: Time.current.iso8601
        })
      rescue StandardError => e
        Rails.logger.error "AI Assistant API error: #{e.message}"
        render_error("Failed to process request: #{e.message}", :internal_server_error)
      end

      # GET /api/v1/ai/conversations
      # List user's AI conversations
      def conversations
        conversations = current_user.ai_conversations
                                    .order(updated_at: :desc)
                                    .limit(20)
                                    .map do |conv|
          {
            id: conv.id,
            title: conv.title,
            last_message: conv.messages.last&.content&.truncate(100),
            updated_at: conv.updated_at.iso8601,
            message_count: conv.messages.count
          }
        end

        render_success(conversations: conversations)
      rescue StandardError => e
        # If AiConversation model doesn't exist yet, return empty
        render_success(conversations: [])
      end

      # GET /api/v1/ai/conversations/:id
      # Get a specific conversation with messages
      def show_conversation
        conversation = current_user.ai_conversations.find(params[:id])

        messages = conversation.messages.order(:created_at).map do |msg|
          {
            role: msg.role,
            content: msg.content,
            timestamp: msg.created_at.iso8601
          }
        end

        render_success({
          id: conversation.id,
          title: conversation.title,
          messages: messages,
          created_at: conversation.created_at.iso8601
        })
      rescue ActiveRecord::RecordNotFound
        render_error("Conversation not found", :not_found)
      end

      # DELETE /api/v1/ai/conversations/:id
      # Delete a conversation
      def destroy_conversation
        conversation = current_user.ai_conversations.find(params[:id])
        conversation.destroy!

        render_success(message: "Conversation deleted")
      rescue ActiveRecord::RecordNotFound
        render_error("Conversation not found", :not_found)
      end

      # POST /api/v1/ai/save_recipe
      # Save an AI-generated recipe to user's recipes
      def save_recipe
        recipe_data = params[:recipe]

        return render_error("Recipe data is required", :bad_request) unless recipe_data.present?

        recipe = current_user.recipes.build(
          title: recipe_data[:title],
          description: recipe_data[:description],
          ingredients: recipe_data[:ingredients],
          preparation: recipe_data[:preparation],
          time_to_make: recipe_data[:time_to_make].to_i,
          difficulty: recipe_data[:difficulty].to_i,
          healthiness: recipe_data[:healthiness].to_i
        )

        if recipe.save
          render_success({
            message: "Recipe saved successfully",
            recipe: {
              id: recipe.id,
              title: recipe.title,
              created_at: recipe.created_at.iso8601
            }
          }, :created)
        else
          render_error(recipe.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      private

      def get_conversation_history(conversation_id)
        return [] unless conversation_id.present?

        # Try to get from AiConversation model if it exists
        begin
          conversation = current_user.ai_conversations.find(conversation_id)
          conversation.messages.order(:created_at).map do |msg|
            { role: msg.role, content: msg.content }
          end
        rescue ActiveRecord::RecordNotFound, NoMethodError
          []
        end
      end

      def store_conversation(conversation_id, user_message, ai_response)
        # For now, generate a simple conversation ID
        # In production, you'd want to store this in a proper model
        conversation_id || SecureRandom.uuid
      end
    end
  end
end

