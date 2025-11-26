class RecipesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_recipe, only: [:show, :edit, :update, :destroy]
  before_action :reload_recipe_schema, only: [:create, :update], if: -> { Rails.env.development? }

  def index
    @categories = Category.all
    @cuisines   = Cuisine.all
    @food_types = FoodType.all
    @quick_filters = available_quick_filters
    filters = request.query_parameters.deep_dup.with_indifferent_access.symbolize_keys
    quick_slug = params[:preset].presence || extract_quick_filter_slug(filters[:search])
    @active_quick_filter = @quick_filters.find { |f| f[:slug] == quick_slug } if quick_slug.present?
    if @active_quick_filter
      filters.merge!(@active_quick_filter[:params])
      filters[:search] = nil if quick_slug == extract_quick_filter_slug(filters[:search])
    end
    @filters = filters
    
    # Base query
    base_recipes = Recipe.includes(:user, :category, :cuisine, :food_type)
    
    # If user is signed in, show followed users' posts + own posts, then recommended
    if user_signed_in?
      # Get IDs of users being followed
      followed_user_ids = current_user.following.pluck(:id)
      # Include current user's own posts
      followed_user_ids << current_user.id
      
      # Get recipes from followed users + own posts
      followed_recipes = base_recipes.where(user_id: followed_user_ids).order(created_at: :desc)
      
      # If we have fewer than 10 recipes from followed users, add recommended recipes
      if followed_recipes.count < 10
        recommended_ids = base_recipes.top_of_month(20).pluck(:id)
        # Exclude recipes already in followed_recipes
        followed_recipe_ids = followed_recipes.pluck(:id)
        additional_ids = recommended_ids - followed_recipe_ids
        
        # Combine followed recipes with recommended
        all_ids = followed_recipe_ids + additional_ids
        @recipes = base_recipes.where(id: all_ids).order(created_at: :desc)
        @showing_recommended = true if additional_ids.any?
      else
        @recipes = followed_recipes
      end
    else
      # For non-signed-in users, show all recipes
      @recipes = base_recipes.order(created_at: :desc)
    end
    
    # Search by recipe name
    if filters[:search].present?
      @recipes = @recipes.where("title ILIKE ?", "%#{filters[:search]}%")
    end
    
    # Filter by category
    if filters[:category_id].present?
      @recipes = @recipes.where(category_id: filters[:category_id])
    end
    
    # Filter by cuisine (region)
    if filters[:cuisine_id].present?
      @recipes = @recipes.where(cuisine_id: filters[:cuisine_id])
    end
    
    # Filter by food type
    if filters[:food_type_id].present?
      @recipes = @recipes.where(food_type_id: filters[:food_type_id])
    end
    
    # Filter by calories (lower than)
    if filters[:max_calories].present? && filters[:max_calories].to_s.strip.present?
      calories = filters[:max_calories].to_i
      if calories > 0
        @recipes = @recipes.where("(nutrition->>'calories')::int <= ?", calories)
      end
    end
    
    # Filter by protein (lower than)
    if filters[:max_protein].present? && filters[:max_protein].to_s.strip.present?
      protein = filters[:max_protein].to_f
      if protein > 0
        @recipes = @recipes.where("(nutrition->>'protein')::float <= ?", protein)
      end
    end
    
    # Filter by fat (lower than)
    if filters[:max_fat].present? && filters[:max_fat].to_s.strip.present?
      fat = filters[:max_fat].to_f
      if fat > 0
        @recipes = @recipes.where("(nutrition->>'fat')::float <= ?", fat)
      end
    end
    
    # Filter by carbs (lower than)
    if filters[:max_carbs].present? && filters[:max_carbs].to_s.strip.present?
      carbs = filters[:max_carbs].to_f
      if carbs > 0
        @recipes = @recipes.where("(nutrition->>'carbs')::float <= ?", carbs)
      end
    end
    
    # Filter by sugar (lower than)
    if filters[:max_sugar].present? && filters[:max_sugar].to_s.strip.present?
      sugar = filters[:max_sugar].to_f
      if sugar > 0
        @recipes = @recipes.where("(nutrition->>'sugar')::float <= ?", sugar)
      end
    end
    
    # Filter by ingredient (legacy)
    if filters[:ingredient].present?
      @recipes = @recipes.where("ingredients ILIKE ?", "%#{filters[:ingredient]}%")
    end

    # Filter by rating (average of comments)
    if filters[:min_rating].present? && filters[:min_rating].to_f > 0
      min_rating = filters[:min_rating].to_f
      rating_sql = <<~SQL
        COALESCE(
          (SELECT AVG(comments.rating)
           FROM comments
           WHERE comments.recipe_id = recipes.id
             AND comments.rating IS NOT NULL),
          0
        ) >= ?
      SQL
      @recipes = @recipes.where(rating_sql, min_rating)
    end

    # Filter by difficulty
    if filters[:min_difficulty].present? && filters[:min_difficulty].to_i > 0
      @recipes = @recipes.where("difficulty >= ?", filters[:min_difficulty].to_i)
    end

    # Filter by healthiness
    if filters[:min_healthiness].present? && filters[:min_healthiness].to_i > 0
      @recipes = @recipes.where("healthiness >= ?", filters[:min_healthiness].to_i)
    end

    # Filter by time to make
    if filters[:min_time].present? && filters[:min_time].to_i > 0
      @recipes = @recipes.where("time_to_make >= ?", filters[:min_time].to_i)
    end

    if filters[:max_time].present? && filters[:max_time].to_i > 0
      @recipes = @recipes.where("time_to_make > 0 AND time_to_make <= ?", filters[:max_time].to_i)
    end
    
    # Top recipes for sidebar
    @top_day = Recipe.includes(:user).top_of_day(10)
    @top_week = Recipe.includes(:user).top_of_week(10)
    @top_month = Recipe.includes(:user).top_of_month(10)
    @top_year = Recipe.includes(:user).top_of_year(10)

    @feed_stats = {
      total_recipes: Recipe.count,
      avg_time: Recipe.where.not(time_to_make: nil).average(:time_to_make)&.round,
      avg_rating: Comment.where.not(rating: nil).average(:rating)&.round(1)
    }
  end

  def top_recipes
    @categories = Category.all
    @cuisines   = Cuisine.all
    @food_types = FoodType.all
    
    # Base query for top recipes
    period = params[:period] || 'day'
    
    case period
    when 'day'
      base_recipes = Recipe.includes(:user, :category, :cuisine, :food_type).created_today
    when 'week'
      base_recipes = Recipe.includes(:user, :category, :cuisine, :food_type).created_this_week
    when 'month'
      base_recipes = Recipe.includes(:user, :category, :cuisine, :food_type).created_this_month
    when 'year'
      base_recipes = Recipe.includes(:user, :category, :cuisine, :food_type).created_this_year
    else
      base_recipes = Recipe.includes(:user, :category, :cuisine, :food_type).created_today
    end
    
    # Order by likes
    @recipes = base_recipes.top_by_likes
    
    # Filter by difficulty (stars)
    if params[:min_difficulty].present? && params[:min_difficulty].to_i > 0
      @recipes = @recipes.where("difficulty >= ?", params[:min_difficulty].to_i)
    end
    
    # Filter by healthiness (stars)
    if params[:min_healthiness].present? && params[:min_healthiness].to_i > 0
      @recipes = @recipes.where("healthiness >= ?", params[:min_healthiness].to_i)
    end
    
    # Filter by time to prepare (max)
    if params[:max_time].present? && params[:max_time].to_i > 0
      @recipes = @recipes.where("time_to_make <= ?", params[:max_time].to_i)
    end
    
    # Filter by time to prepare (min)
    if params[:min_time].present? && params[:min_time].to_i > 0
      @recipes = @recipes.where("time_to_make >= ?", params[:min_time].to_i)
    end
    
    # Filter by category
    if params[:category_id].present?
      @recipes = @recipes.where(category_id: params[:category_id])
    end
    
    # Filter by cuisine (region)
    if params[:cuisine_id].present?
      @recipes = @recipes.where(cuisine_id: params[:cuisine_id])
    end
    
    # Filter by food type
    if params[:food_type_id].present?
      @recipes = @recipes.where(food_type_id: params[:food_type_id])
    end
    
    # Filter by calories (lower than)
    if params[:max_calories].present? && params[:max_calories].strip.present?
      calories = params[:max_calories].to_i
      if calories > 0
        @recipes = @recipes.where("(nutrition->>'calories')::int <= ?", calories)
      end
    end
    
    @current_period = period
  end

  def show; end
  def new
    @recipe = Recipe.new
  end
  def create
    @recipe = Recipe.new(recipe_params)
    @recipe.user = current_user
    
    # Convert empty strings to nil for optional fields
    @recipe.category_id = nil if @recipe.category_id.blank?
    @recipe.cuisine_id = nil if @recipe.cuisine_id.blank?
    @recipe.food_type_id = nil if @recipe.food_type_id.blank?
    
    # Set default values for rating fields if not provided
    @recipe.difficulty = 0 if @recipe.difficulty.blank?
    @recipe.time_to_make = 0 if @recipe.time_to_make.blank?
    @recipe.healthiness = 0 if @recipe.healthiness.blank?
    
    map_free_text_taxonomies!(@recipe)
    if @recipe.save
        redirect_to recipes_path, notice: "Rețeta a fost publicată!"
    else
        render :new, status: :unprocessable_entity
    end
  end

  def edit; end
  def update
    @recipe.assign_attributes(recipe_params)
    
    # Convert empty strings to nil for optional fields
    @recipe.category_id = nil if @recipe.category_id.blank?
    @recipe.cuisine_id = nil if @recipe.cuisine_id.blank?
    @recipe.food_type_id = nil if @recipe.food_type_id.blank?
    
    # Set default values for rating fields if not provided
    @recipe.difficulty = 0 if @recipe.difficulty.blank?
    @recipe.time_to_make = 0 if @recipe.time_to_make.blank?
    @recipe.healthiness = 0 if @recipe.healthiness.blank?
    
    map_free_text_taxonomies!(@recipe)
    if @recipe.save
      redirect_to @recipe, notice: "Rețetă salvată!"
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @recipe.destroy
    redirect_to recipes_path, notice: "Rețeta a fost ștearsă."
  end

  private

  def set_recipe
    @recipe = Recipe.includes(:user, :category, :cuisine, :food_type, comments: :user).find(params[:id])
  end

  def reload_recipe_schema
    # Force reload schema in development to pick up new columns
    Recipe.reset_column_information
  end

  # Permite DOAR coloane reale și câmpuri nested. NU include category_name, cuisine_name, food_type_name!
  def recipe_params
    params.require(:recipe).permit(
      :title, :description, :ingredients, :preparation,
      :category_id, :cuisine_id, :food_type_id, :cover_photo_id,
      :difficulty, :time_to_make, :healthiness,
      photos: [], photos_order: [],
      nutrition: [:calories, :sugar, :protein, :fat, :carbs]
    )
  end

  # Process photos order and cover photo
  def map_free_text_taxonomies!(recipe)
    # Categories, cuisines, and food types are now fixed - users can only select from existing ones
    if recipe.photos_order.present?
      recipe.photos_order = Array(recipe.photos_order).map(&:to_i)
    end
    if recipe.cover_photo_id.present?
      recipe.cover_photo_id = recipe.cover_photo_id.to_i
    end
  end

  def extract_quick_filter_slug(search_query)
    return if search_query.blank?
    tokens = search_query.downcase.scan(/#([\w\-]+)/).flatten
    tokens.first
  end
end
