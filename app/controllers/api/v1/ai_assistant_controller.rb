# frozen_string_literal: true

module Api
  module V1
    class AiAssistantController < BaseController
      before_action :authenticate_user!

      # POST /api/v1/ai/chat
      # Send a message to the AI assistant
      # Params:
      #   - message: string (required)
      #   - provider: string (optional) - "local", "llama", or "openai"
      #   - conversation_id: string (optional)
      def chat
        message = params[:message]&.strip
        provider = params[:provider] || AiRecipeAssistant::PROVIDER_LOCAL
        conversation_id = params[:conversation_id]

        return render_error("Message is required", :bad_request) if message.blank?

        # Validate provider
        valid_providers = [
          AiRecipeAssistant::PROVIDER_LOCAL,
          AiRecipeAssistant::PROVIDER_LLAMA,
          AiRecipeAssistant::PROVIDER_OPENAI
        ]
        unless valid_providers.include?(provider)
          return render_error("Invalid provider. Use: local, llama, or openai", :bad_request)
        end

        # Initialize AI assistant with selected provider
        assistant = AiRecipeAssistant.new(user: current_user, provider: provider)

        # Get conversation history
        conversation_history = get_conversation_history(conversation_id)

        # Get AI response
        response = assistant.chat(message, conversation_history: conversation_history)

        # Store conversation
        new_conversation_id = store_conversation(conversation_id, message, response)

        render_success({
          conversation_id: new_conversation_id,
          response: response,
          provider_used: response["ai_provider"] || provider,
          timestamp: Time.current.iso8601
        })
      rescue StandardError => e
        Rails.logger.error "AI Assistant API error: #{e.message}"
        Rails.logger.error e.backtrace.first(10).join("\n")
        render_error("Failed to process request: #{e.message}", :internal_server_error)
      end

      # GET /api/v1/ai/providers
      # List available AI providers
      def providers
        available = AiRecipeAssistant.available_providers
        
        providers_info = [
          {
            id: "local",
            name: "Căutare Locală",
            description: "Caută în rețetele existente din comunitate",
            available: true,
            cost: "Gratuit",
            icon: "🔍"
          },
          {
            id: "llama",
            name: "Llama 3.1",
            description: "Generează rețete cu AI local (Ollama)",
            available: available.include?(AiRecipeAssistant::PROVIDER_LLAMA),
            cost: "Gratuit",
            icon: "🦙",
            setup_required: !available.include?(AiRecipeAssistant::PROVIDER_LLAMA)
          },
          {
            id: "openai",
            name: "OpenAI GPT-4",
            description: "Generare premium cu GPT-4",
            available: available.include?(AiRecipeAssistant::PROVIDER_OPENAI),
            cost: "Premium",
            icon: "✨",
            setup_required: !available.include?(AiRecipeAssistant::PROVIDER_OPENAI)
          }
        ]

        render_success(providers: providers_info, default: "local")
      end

      # GET /api/v1/ai/conversations
      # List user's AI conversations
      def conversations
        # For now, return empty - conversations are stored in session for web
        # In production, you'd want to store in database
        render_success(conversations: [])
      end

      # GET /api/v1/ai/conversations/:id
      # Get a specific conversation with messages
      def show_conversation
        render_error("Conversation not found", :not_found)
      end

      # DELETE /api/v1/ai/conversations/:id
      # Delete a conversation
      def destroy_conversation
        render_success(message: "Conversation deleted")
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
        # In production, fetch from database
        []
      end

      def store_conversation(conversation_id, user_message, ai_response)
        # In production, store in database
        conversation_id || SecureRandom.uuid
      end
    end
  end
end
