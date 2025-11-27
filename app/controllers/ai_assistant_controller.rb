# frozen_string_literal: true

class AiAssistantController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @conversation_history = session[:ai_conversation] || []
  end

  def chat
    message = params[:message]&.strip
    
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

    # Initialize AI assistant
    assistant = AiRecipeAssistant.new(user: current_user)
    
    # Get conversation history from session
    conversation_history = session[:ai_conversation] || []
    
    # Get AI response
    response = assistant.chat(message, conversation_history: conversation_history)
    
    # Store in session
    conversation_history << { role: "user", content: message, timestamp: Time.current }
    conversation_history << { role: "assistant", content: response, timestamp: Time.current }
    session[:ai_conversation] = conversation_history.last(20) # Keep last 20 messages

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("ai-messages", partial: "ai_assistant/user_message", locals: { message: message }),
          turbo_stream.append("ai-messages", partial: "ai_assistant/assistant_message", locals: { response: response }),
          turbo_stream.replace("ai-input-form", partial: "ai_assistant/input_form")
        ]
      end
      format.json { render json: response }
    end
  rescue StandardError => e
    Rails.logger.error "AI Assistant error: #{e.message}"
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("ai-messages", partial: "ai_assistant/error_message",
          locals: { message: "A apărut o eroare. Te rog să încerci din nou." })
      end
      format.json { render json: { error: e.message }, status: :internal_server_error }
    end
  end

  def clear_conversation
    session[:ai_conversation] = []
    redirect_to ai_assistant_path, notice: "Conversația a fost ștearsă."
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

