class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def index
    # Dashboard stats
    @total_users = User.count
    @total_recipes = Recipe.count
    @total_categories = Category.count
    @total_cuisines = Cuisine.count
    @total_food_types = FoodType.count

    # Recent activity
    @new_users_today = User.where("created_at >= ?", Time.current.beginning_of_day).count
    @new_recipes_today = Recipe.where("created_at >= ?", Time.current.beginning_of_day).count
    @new_users_week = User.where("created_at >= ?", 1.week.ago).count
    @new_recipes_week = Recipe.where("created_at >= ?", 1.week.ago).count
    @new_users_month = User.where("created_at >= ?", 1.month.ago).count
    @new_recipes_month = Recipe.where("created_at >= ?", 1.month.ago).count
  end

  def settings
    @site_setting = SiteSetting.instance
  end

  def update_settings
    @site_setting = SiteSetting.instance
    if @site_setting.update(site_setting_params)
      redirect_to admin_settings_path, notice: t("admin.settings.updated")
    else
      render :settings, status: :unprocessable_entity
    end
  end

  def users
    @users = User.includes(:recipes, :followers, :following)
                 .order(created_at: :desc)
                 .page(params[:page])
  end

  def recipes
    @recipes = Recipe.includes(:user, :category, :cuisine, :food_type)
                     .order(created_at: :desc)
                     .page(params[:page])
  end

  def categories
    @categories = Category.all.order(:name)
  end

  def cuisines
    @cuisines = Cuisine.all.order(:name)
  end

  def food_types
    @food_types = FoodType.all.order(:name)
  end

  def reset_password
    @user = User.find(params[:user_id])
    new_password = Devise.friendly_token[0, 12]
    @user.update(password: new_password, password_confirmation: new_password)
    redirect_to admin_users_path, notice: t("admin.users.password_reset", email: @user.email, password: new_password)
  end

  def reports
    @period = params[:period] || "week"

    case @period
    when "day"
      start_date = Time.current.beginning_of_day
    when "week"
      start_date = 1.week.ago
    when "month"
      start_date = 1.month.ago
    when "year"
      start_date = 1.year.ago
    else
      start_date = 1.week.ago
    end

    @new_users = User.where("created_at >= ?", start_date).count
    @new_recipes = Recipe.where("created_at >= ?", start_date).count
    @new_comments = Comment.where("created_at >= ?", start_date).count
    @new_likes = Like.where("created_at >= ?", start_date).count
    @new_follows = Follow.where("created_at >= ?", start_date).count
  end

  private

  def ensure_admin
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.unauthorized")
    end
  end

  def site_setting_params
    params.require(:site_setting).permit(:contact_email, :contact_phone, :contact_address,
                                         :primary_color, :secondary_color, :accent_color)
  end
end
