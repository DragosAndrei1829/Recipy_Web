class UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :search ]

  def show
    @user = User.find_by(slug: params[:id]) || User.find(params[:id])
    @recipes = @user.recipes.includes(:category, :cuisine, :food_type, photos_attachments: :blob)
                    .order(created_at: :desc)
    @collections = @user.collections.includes(:recipes).recent.limit(6)
    @is_following = user_signed_in? && current_user.following.include?(@user)
  end

  def followers
    @user = User.find_by(slug: params[:id]) || User.find(params[:id])
    @followers = @user.followers.includes(:avatar_attachment)

    # Only allow viewing followers list if it's the current user's profile
    unless user_signed_in? && current_user == @user
      redirect_to user_path(@user), alert: t("follows.cannot_view_followers")
    end
  end

  def search
    @query = params[:q].to_s.strip
    if @query.present?
      @users = User.where("username ILIKE ? OR email ILIKE ?", "%#{@query}%", "%#{@query}%")
                   .limit(10)
    else
      @users = []
    end

    respond_to do |format|
      format.html { render partial: "users/search_results", locals: { users: @users, query: @query } }
      format.json { render json: @users.map { |u| { id: u.id, username: u.username, email: u.email, avatar_url: u.avatar.attached? ? url_for(u.avatar.variant(resize_to_fill: [ 40, 40 ])) : nil } } }
    end
  rescue => e
    respond_to do |format|
      format.html { render partial: "users/search_results", locals: { users: [], query: @query } }
      format.json { render json: [] }
    end
  end

  def change_theme
    unless user_signed_in?
      redirect_to root_path, alert: t("users.must_be_logged_in")
      return
    end

    theme = Theme.find(params[:theme_id])
    current_user.update(theme: theme)
    # Force a full page reload to apply new CSS variables
    redirect_to request.referer || root_path, notice: t("users.theme_changed", theme: theme.name)
  end
end
