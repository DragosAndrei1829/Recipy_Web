class UserShortcutsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_shortcut, only: [:edit, :update, :destroy]

  def index
    @user_shortcuts = current_user.user_shortcuts.ordered
  end

  def new
    @user_shortcut = current_user.user_shortcuts.build
  end

  def create
    @user_shortcut = current_user.user_shortcuts.build(user_shortcut_params)
    
    if @user_shortcut.save
      redirect_to user_shortcuts_path(locale: I18n.locale), notice: t('user_shortcuts.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user_shortcut.update(user_shortcut_params)
      redirect_to user_shortcuts_path(locale: I18n.locale), notice: t('user_shortcuts.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user_shortcut.destroy
    redirect_to user_shortcuts_path(locale: I18n.locale), notice: t('user_shortcuts.destroyed')
  end

  def reorder
    params[:order].each_with_index do |id, index|
      current_user.user_shortcuts.find(id).update(position: index)
    end
    head :ok
  end

  private

  def set_user_shortcut
    @user_shortcut = current_user.user_shortcuts.find(params[:id])
  end

  def user_shortcut_params
    params.require(:user_shortcut).permit(:name, :url, :color, :icon, :position)
  end
end
