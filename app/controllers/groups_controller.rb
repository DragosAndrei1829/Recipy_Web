# frozen_string_literal: true

class GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group, only: [:show, :edit, :update, :destroy, :chat, :settings, :members, :recipes, :add_recipe, :remove_recipe, :leave, :regenerate_invite]
  before_action :authorize_member!, only: [:show, :chat, :recipes, :add_recipe, :leave]
  before_action :authorize_admin!, only: [:edit, :update, :destroy, :settings, :members, :regenerate_invite]

  def index
    @my_groups = current_user.groups.includes(:owner).order(created_at: :desc)
    @owned_groups = current_user.owned_groups.includes(:owner).order(created_at: :desc)
  end

  def show
    @group_recipes = @group.group_recipes.includes(recipe: [:user, :category, :cuisine]).order(created_at: :desc).page(params[:page]).per(12)
    @recent_messages = @group.recent_messages(20)
    @membership = @group.group_memberships.find_by(user: current_user)
  end

  def new
    @group = Group.new
  end

  def create
    @group = current_user.owned_groups.build(group_params)

    if @group.save
      redirect_to group_path(@group), notice: "Grupul a fost creat cu succes! Codul de invitație: #{@group.invite_code}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to group_path(@group), notice: "Grupul a fost actualizat."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_path, notice: "Grupul a fost șters."
  end

  # Chat page
  def chat
    @messages = @group.group_messages.includes(:user).order(created_at: :asc).last(100)
    @membership = @group.group_memberships.find_by(user: current_user)
  end

  # Send message in chat
  def send_message
    @group = Group.find(params[:id])
    return head :forbidden unless @group.member?(current_user)

    @message = @group.group_messages.build(user: current_user, content: params[:content])

    respond_to do |format|
      if @message.save
        format.turbo_stream
        format.json { render json: { success: true, message: @message } }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message-form", partial: "groups/message_form", locals: { group: @group, error: @message.errors.full_messages.first }) }
        format.json { render json: { success: false, errors: @message.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # Group settings
  def settings
    @members = @group.group_memberships.includes(:user).order(role: :asc, joined_at: :desc)
  end

  # Members management
  def members
    @members = @group.group_memberships.includes(:user).order(role: :asc, joined_at: :desc)
  end

  # Update member role
  def update_member_role
    @group = Group.find(params[:id])
    return head :forbidden unless @group.admin?(current_user)

    user = User.find(params[:user_id])
    new_role = params[:role]

    if @group.update_member_role(user, new_role)
      redirect_to members_group_path(@group), notice: "Rolul a fost actualizat."
    else
      redirect_to members_group_path(@group), alert: "Nu s-a putut actualiza rolul."
    end
  end

  # Remove member
  def remove_member
    @group = Group.find(params[:id])
    return head :forbidden unless @group.admin?(current_user)

    user = User.find(params[:user_id])

    if @group.remove_member(user)
      redirect_to members_group_path(@group), notice: "Membrul a fost eliminat."
    else
      redirect_to members_group_path(@group), alert: "Nu s-a putut elimina membrul."
    end
  end

  # Recipes in group
  def recipes
    @group_recipes = @group.group_recipes.includes(recipe: [:user, :category, :cuisine, photos_attachments: :blob]).order(created_at: :desc)
  end

  # Add recipe to group
  def add_recipe
    recipe = Recipe.find(params[:recipe_id])

    if @group.add_recipe(recipe, added_by: current_user, note: params[:note])
      respond_to do |format|
        format.html { redirect_to recipes_group_path(@group), notice: "Rețeta a fost adăugată în grup." }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { redirect_to recipes_group_path(@group), alert: "Rețeta este deja în grup sau nu ai permisiunea." }
        format.json { render json: { success: false, error: "Nu s-a putut adăuga rețeta" }, status: :unprocessable_entity }
      end
    end
  end

  # Remove recipe from group
  def remove_recipe
    recipe = Recipe.find(params[:recipe_id])

    if @group.remove_recipe(recipe, removed_by: current_user)
      redirect_to recipes_group_path(@group), notice: "Rețeta a fost eliminată din grup."
    else
      redirect_to recipes_group_path(@group), alert: "Nu ai permisiunea de a elimina această rețetă."
    end
  end

  # Join group by invite code
  def join
    result = Group.join_by_invite_code(params[:invite_code], current_user)

    if result[:success]
      redirect_to group_path(result[:group]), notice: "Te-ai alăturat grupului #{result[:group].name}!"
    else
      redirect_to groups_path, alert: result[:error]
    end
  end

  # Leave group
  def leave
    if @group.owner == current_user
      redirect_to group_path(@group), alert: "Nu poți părăsi grupul pe care l-ai creat. Transferă ownership sau șterge grupul."
    elsif @group.remove_member(current_user)
      redirect_to groups_path, notice: "Ai părăsit grupul."
    else
      redirect_to group_path(@group), alert: "A apărut o eroare."
    end
  end

  # Regenerate invite code
  def regenerate_invite
    @group.regenerate_invite_code!
    redirect_to settings_group_path(@group), notice: "Codul de invitație a fost regenerat: #{@group.invite_code}"
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :description, :is_private, :cover_image)
  end

  def authorize_member!
    unless @group.viewable_by?(current_user)
      redirect_to groups_path, alert: "Nu ai acces la acest grup."
    end
  end

  def authorize_admin!
    unless @group.admin?(current_user)
      redirect_to group_path(@group), alert: "Nu ai permisiunea de a face această acțiune."
    end
  end
end

