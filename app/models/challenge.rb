# frozen_string_literal: true

class Challenge < ApplicationRecord
  belongs_to :user # Creator
  has_many :challenge_participants, dependent: :destroy
  has_many :participants, through: :challenge_participants, source: :user
  has_many :submissions, -> { where.not(recipe_id: nil).where(status: 'submitted') }, class_name: "ChallengeParticipant"
  has_many :submitted_recipes, through: :submissions, source: :recipe

  # Slug generation
  before_validation :generate_slug, on: :create
  before_validation :regenerate_slug, on: :update, if: :title_changed?

  CHALLENGE_TYPES = %w[recipe cooking_technique ingredient theme seasonal].freeze
  STATUSES = %w[upcoming active completed cancelled].freeze
  
  # Global requirements for creating challenges (not per challenge)
  MIN_LIKES_TO_CREATE = 50
  MIN_AVG_RATING_TO_CREATE = 7.5

  validates :title, presence: true
  validates :challenge_type, presence: true, inclusion: { in: CHALLENGE_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date
  validate :creator_eligibility, unless: -> { user&.admin? }

  scope :active, -> { where(status: "active") }
  scope :upcoming, -> { where(status: "upcoming") }
  scope :completed, -> { where(status: "completed") }
  scope :open_for_participation, -> { where(status: ["upcoming", "active"]) }

  before_validation :set_default_status, on: :create
  before_save :update_status_based_on_dates

  def to_param
    slug.presence || id.to_s
  end

  def self.user_can_create_challenge?(user)
    return false unless user
    return true if user.admin? # Admins can always create challenges
    
    # Check minimum likes requirement (global)
    total_likes = user.recipes.sum(:likes_count)
    return false if total_likes < MIN_LIKES_TO_CREATE
    
    # Check average rating requirement (global)
    user_avg = new.calculate_user_avg_rating(user)
    return false if user_avg < MIN_AVG_RATING_TO_CREATE
    
    true
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

  def user_can_join?(user)
    return false unless user
    return false unless open_for_participation?
    return false if participants.include?(user)
    true
  end

  def open_for_participation?
    status.in?(["upcoming", "active"]) && Date.current >= start_date && Date.current <= end_date
  end

  def active?
    status == "active" && Date.current >= start_date && Date.current <= end_date
  end

  def completed?
    status == "completed" || (end_date < Date.current && status != "cancelled")
  end

  def can_submit?(user)
    return false unless user
    # Any user can submit if they've joined and challenge is active
    return false unless participants.include?(user)
    active? && Date.current <= end_date
  end

  private

  def generate_slug
    return if slug.present?
    self.slug = title.parameterize if title.present?
    # Ensure uniqueness
    if slug.present? && Challenge.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{slug}-#{SecureRandom.hex(4)}"
    end
  end

  def regenerate_slug
    return unless title_changed?
    self.slug = title.parameterize if title.present?
    # Ensure uniqueness
    if slug.present? && Challenge.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{slug}-#{SecureRandom.hex(4)}"
    end
  end

  def set_default_status
    return if status.present?
    # Set default status based on start_date
    if start_date.present?
      self.status = start_date > Date.current ? "upcoming" : "active"
    else
      self.status = "upcoming"
    end
  end

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "trebuie să fie după data de început") if end_date < start_date
  end

  def creator_eligibility
    return unless user_id.present?
    creator = User.find_by(id: user_id)
    return unless creator
    return if creator.admin? # Skip validation for admins
    
    unless Challenge.user_can_create_challenge?(creator)
      errors.add(:base, "Nu ești eligibil să creezi challenge-uri. Ai nevoie de cel puțin #{MIN_LIKES_TO_CREATE} like-uri totale și o medie de rating de cel puțin #{MIN_AVG_RATING_TO_CREATE}/10 pentru rețetele tale.")
    end
  end

  def update_status_based_on_dates
    return if status == "cancelled"
    
    if Date.current < start_date
      self.status = "upcoming"
    elsif Date.current >= start_date && Date.current <= end_date
      self.status = "active"
    elsif Date.current > end_date
      self.status = "completed"
    end
  end
end

