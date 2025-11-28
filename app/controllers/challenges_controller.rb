# frozen_string_literal: true

class ChallengesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_challenge, only: [:show, :edit, :update, :destroy, :join, :submit_recipe]
  before_action :check_eligibility, only: [:new, :create]

  def index
    @challenges = Challenge.includes(:user, :challenge_participants)
                           .order(start_date: :desc)
    
    @active_challenges = Challenge.active.includes(:user).order(end_date: :asc)
    @upcoming_challenges = Challenge.upcoming.includes(:user).order(start_date: :asc)
    @completed_challenges = Challenge.completed.includes(:user).order(end_date: :desc).limit(10)
    
    # Check if user can create challenges (global requirement)
    @user_can_create = user_signed_in? ? Challenge.user_can_create_challenge?(current_user) : false
  end

  def show
    @participants = @challenge.challenge_participants.includes(:user, :recipe).order(Arel.sql("COALESCE(rank, 999999) ASC, submitted_at ASC"))
    
    # Sorting options for owner/admin
    @is_owner_or_admin = user_signed_in? && (@challenge.user == current_user || current_user.admin?)
    
    # Get sorting parameters
    sort_by = params[:sort_by] || 'score'
    sort_order = params[:sort_order] || 'desc'
    
    # Base query for submissions
    submissions = @challenge.submissions.includes(:user, :recipe)
    
    # Apply sorting (only for owner/admin, otherwise default)
    if @is_owner_or_admin && submissions.any?
      @submissions = case sort_by
      when 'likes'
        submissions.joins(:recipe).includes(:user, :recipe).order(Arel.sql("recipes.likes_count #{sort_order}"))
      when 'comments'
        submissions.joins(:recipe).includes(:user, :recipe).order(Arel.sql("recipes.comments_count #{sort_order}"))
      when 'rating'
        # Get submissions with ratings - simpler approach: load all and sort in Ruby
        all_submissions = submissions.includes(:user, recipe: :comments).to_a
        all_submissions.select! { |s| s.recipe&.comments&.where.not(rating: nil)&.any? }
        all_submissions.sort_by! do |s|
          avg = s.recipe.comments.where.not(rating: nil).average(:rating) || 0
          sort_order == 'desc' ? -avg : avg
        end
        @submissions = all_submissions.any? ? all_submissions : submissions.none
      when 'attractiveness'
        # Combined score: likes + comments + rating - load all and calculate in Ruby
        all_submissions = submissions.includes(:user, recipe: :comments).to_a
        all_submissions.select! { |s| s.recipe&.comments&.where.not(rating: nil)&.any? }
        all_submissions.sort_by! do |s|
          likes = s.recipe.likes_count * 10
          comments = s.recipe.comments_count * 5
          rating = (s.recipe.comments.where.not(rating: nil).average(:rating) || 0) * 20
          score = likes + comments + rating
          sort_order == 'desc' ? -score : score
        end
        @submissions = all_submissions.any? ? all_submissions : submissions.none
      when 'submitted_at'
        submissions.includes(:user, :recipe).order(Arel.sql("submitted_at #{sort_order}"))
      else # 'score' (default)
        submissions.includes(:user, :recipe).order(Arel.sql("score #{sort_order}"))
      end
    else
      # Default sorting for regular users
      @submissions = submissions.any? ? submissions.includes(:user, :recipe).order(score: :desc, submitted_at: :asc) : submissions.none
    end
    
    @sort_by = sort_by
    @sort_order = sort_order
    @user_participation = @challenge.challenge_participants.find_by(user: current_user) if user_signed_in?
    @user_recipes = user_signed_in? ? current_user.recipes.order(:title) : []
  end

  def new
    @challenge = current_user.created_challenges.build
    @challenge.start_date = Date.current
    @challenge.end_date = Date.current + 30.days
    @challenge.challenge_type = "recipe"
    @challenge.status = "upcoming" # Set default status
  end

  def create
    @challenge = current_user.created_challenges.build(challenge_params)
    
    # Admins can always create challenges, skip eligibility check
    unless current_user.admin? || Challenge.user_can_create_challenge?(current_user)
      @challenge.errors.add(:base, "Nu ești eligibil să creezi challenge-uri. Ai nevoie de cel puțin #{Challenge::MIN_LIKES_TO_CREATE} like-uri totale și o medie de rating de cel puțin #{Challenge::MIN_AVG_RATING_TO_CREATE}/10 pentru rețetele tale.")
      render :new, status: :unprocessable_entity
      return
    end

    if @challenge.save
      redirect_to @challenge, notice: "Challenge creat cu succes!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize_challenge_owner!
  end

  def update
    authorize_challenge_owner!
    
    if @challenge.update(challenge_params)
      redirect_to @challenge, notice: "Challenge actualizat cu succes!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_challenge_owner!
    
    @challenge.destroy
    redirect_to challenges_path, notice: "Challenge șters cu succes!"
  end

  def join
    # Check if user is the owner
    if @challenge.user == current_user
      redirect_to @challenge, alert: "Tu deții acest challenge. Nu poți participa la propriul tău challenge."
      return
    end

    unless @challenge.user_can_join?(current_user)
      redirect_to @challenge, alert: "Nu poți participa la acest challenge."
      return
    end

    participant = @challenge.challenge_participants.build(user: current_user, status: "joined")
    
    if participant.save
      redirect_to @challenge, notice: "Te-ai înscris în challenge cu succes!"
    else
      redirect_to @challenge, alert: "Eroare la înscriere: #{participant.errors.full_messages.join(', ')}"
    end
  end

  def submit_recipe
    @user_participation = @challenge.challenge_participants.find_by(user: current_user)
    
    unless @user_participation
      redirect_to @challenge, alert: "Trebuie să te înscrii mai întâi în challenge."
      return
    end

    recipe = Recipe.find(params[:recipe_id])
    
    unless recipe.user == current_user
      redirect_to @challenge, alert: "Poți trimite doar rețetele tale."
      return
    end

    if @user_participation.submit_recipe!(recipe)
      redirect_to @challenge, notice: "Rețetă trimisă cu succes!"
    else
      redirect_to @challenge, alert: "Nu poți trimite rețeta acum."
    end
  end

  private

  def set_challenge
    @challenge = Challenge.find_by(slug: params[:id]) || Challenge.find(params[:id])
  end

  def check_eligibility
    # Admins can always create challenges, skip eligibility check
    return if current_user.admin?
    
    unless Challenge.user_can_create_challenge?(current_user)
      redirect_to challenges_path, 
                  alert: "Nu ești eligibil să creezi challenge-uri. Ai nevoie de cel puțin #{Challenge::MIN_LIKES_TO_CREATE} like-uri totale și o medie de rating de cel puțin #{Challenge::MIN_AVG_RATING_TO_CREATE}/10 pentru rețetele tale."
      return
    end
  end

  def calculate_user_avg_rating(user)
    return 0.0 unless user
    
    # Get average rating for each recipe
    recipes = user.recipes.includes(:comments)
    return 0.0 if recipes.empty?
    
    total_rating = 0.0
    recipes_with_ratings = 0
    
    recipes.each do |recipe|
      avg = recipe.comments.where.not(rating: nil).average(:rating)
      if avg
        total_rating += avg
        recipes_with_ratings += 1
      end
    end
    
    return 0.0 if recipes_with_ratings == 0
    (total_rating / recipes_with_ratings).round(1)
  end
  
  helper_method :calculate_user_avg_rating

  def authorize_challenge_owner!
    unless @challenge.user == current_user || current_user.admin?
      redirect_to @challenge, alert: "Nu ai permisiunea să modifici acest challenge."
    end
  end

  def challenge_params
    params.require(:challenge).permit(:title, :description, :challenge_type, :start_date, :end_date, 
                                      :rules, :prize, :status)
  end
end
