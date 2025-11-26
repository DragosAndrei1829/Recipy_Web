class SharedRecipesController < ApplicationController
  before_action :authenticate_user!

  def index
    @shared_recipes = current_user.received_shared_recipes.includes(:sender, :recipe).recent
  end

  def create
    @recipe = Recipe.find(params[:recipe_id])
    recipient = User.find(params[:recipient_id])

    if recipient == current_user
      redirect_back(fallback_location: recipe_path(@recipe), alert: t("shared_recipes.cannot_share_with_self"))
      return
    end

    # Find or create conversation
    @conversation = Conversation.between(current_user, recipient).first
    unless @conversation
      @conversation = Conversation.create!(
        sender: current_user,
        recipient: recipient
      )
    end

    @shared_recipe = SharedRecipe.create!(
      sender: current_user,
      recipient: recipient,
      recipe: @recipe,
      message: params[:message],
      conversation: @conversation
    )

    redirect_to conversation_path(@conversation), notice: t("shared_recipes.created")
  end
end
