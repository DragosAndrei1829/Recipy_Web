# frozen_string_literal: true

class AiAssistantController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversation_history = session[:ai_conversation] || []
    @current_provider = session[:ai_provider] || AiRecipeAssistant::PROVIDER_LOCAL
    @available_providers = AiRecipeAssistant.available_providers
  end

  def chat
    message = params[:message]&.strip
    provider = params[:provider] || session[:ai_provider] || AiRecipeAssistant::PROVIDER_LOCAL

    if message.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("ai-messages", partial: "ai_assistant/error_message",
            locals: { message: "Te rog să scrii un mesaj." })
        end
        format.json { render json: { error: "Message is required" }, status: :unprocessable_entity }
      end
      return
    end

    # Store provider preference
    session[:ai_provider] = provider

    # Initialize AI assistant with selected provider
    assistant = AiRecipeAssistant.new(user: current_user, provider: provider)

    # Get conversation history from session
    conversation_history = session[:ai_conversation] || []

    # Get AI response
    response = assistant.chat(message, conversation_history: conversation_history)

    # Store in session
    conversation_history << { role: "user", content: message, timestamp: Time.current }
    conversation_history << { role: "assistant", content: response, timestamp: Time.current }
    session[:ai_conversation] = conversation_history.last(20)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("ai-messages", partial: "ai_assistant/user_message", locals: { message: message }),
          turbo_stream.append("ai-messages", partial: "ai_assistant/assistant_message", locals: { response: response }),
          turbo_stream.replace("ai-input-form", partial: "ai_assistant/input_form", locals: { current_provider: provider })
        ]
      end
      format.json { render json: response }
    end
  rescue StandardError => e
    Rails.logger.error "AI Assistant error: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("ai-messages", partial: "ai_assistant/error_message",
          locals: { message: "A apărut o eroare: #{e.message}" })
      end
      format.json { render json: { error: e.message }, status: :internal_server_error }
    end
  end

  # Generate recipe with AI (when user clicks "Generate with AI")
  def generate
    ingredients = params[:ingredients] || []
    provider = params[:provider] || AiRecipeAssistant::PROVIDER_LLAMA

    if ingredients.empty?
      return render json: { error: "Ingredients required" }, status: :unprocessable_entity
    end

    assistant = AiRecipeAssistant.new(user: current_user, provider: provider)
    parsed_request = {
      "ingredients" => ingredients,
      "preferences" => params[:preferences] || {}
    }

    response = case provider
    when AiRecipeAssistant::PROVIDER_OPENAI
      assistant.send(:generate_recipe_with_openai, parsed_request)
    when AiRecipeAssistant::PROVIDER_LLAMA
      assistant.send(:generate_recipe_with_llama, parsed_request)
    else
      { "message" => "Provider invalid", "type" => "error" }
    end

    render json: response
  end

  def clear_conversation
    session[:ai_conversation] = []
    redirect_to ai_assistant_path, notice: "Conversația a fost ștearsă."
  end

  def set_provider
    provider = params[:provider]
    if [AiRecipeAssistant::PROVIDER_LOCAL, AiRecipeAssistant::PROVIDER_LLAMA, AiRecipeAssistant::PROVIDER_OPENAI].include?(provider)
      session[:ai_provider] = provider
      render json: { success: true, provider: provider }
    else
      render json: { error: "Invalid provider" }, status: :unprocessable_entity
    end
  end

  def save_recipe
    recipe_data = params[:recipe]

    unless recipe_data.present?
      return render json: { error: "No recipe data provided" }, status: :unprocessable_entity
    end

    @recipe = current_user.recipes.build(
      title: recipe_data[:title],
      description: recipe_data[:description],
      ingredients: recipe_data[:ingredients],
      preparation: recipe_data[:preparation],
      time_to_make: recipe_data[:time_to_make].to_i,
      difficulty: recipe_data[:difficulty].to_i,
      healthiness: recipe_data[:healthiness].to_i
    )

    if @recipe.save
      render json: {
        success: true,
        message: "Rețeta a fost salvată cu succes!",
        recipe_id: @recipe.id,
        recipe_url: recipe_path(@recipe)
      }
    else
      render json: {
        success: false,
        errors: @recipe.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end
