# frozen_string_literal: true

class ChallengeParticipant < ApplicationRecord
  belongs_to :challenge, counter_cache: :participants_count
  belongs_to :user
  belongs_to :recipe, optional: true

  STATUSES = %w[joined submitted disqualified winner].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :challenge_id, message: "Ești deja înscris în acest challenge" }
  validate :challenge_not_closed

  scope :joined, -> { where(status: "joined") }
  scope :submitted, -> { where(status: "submitted") }
  scope :winners, -> { where(status: "winner") }
  scope :ranked, -> { where.not(rank: nil).order(:rank) }

  after_create :increment_participants_count
  after_update :increment_submissions_count, if: :saved_change_to_status?
  after_update :calculate_score, if: :saved_change_to_recipe_id?

  def submit_recipe!(recipe)
    return false unless challenge.can_submit?(user)
    return false unless recipe.user == user
    
    update!(
      recipe: recipe,
      submitted_at: Time.current,
      status: "submitted"
    )
    calculate_score
    true
  end

  def calculate_score
    return unless recipe && status == "submitted"
    
    # Score based on likes, rating, and time submitted (earlier = better)
    likes_score = recipe.likes_count * 10
    rating_score = (recipe.comments.where.not(rating: nil).average(:rating) || 0) * 20
    time_bonus = challenge.end_date - recipe.created_at.to_date # Days before deadline
    
    total_score = likes_score + rating_score + (time_bonus * 5)
    update_column(:score, total_score.round(2))
    
    # Update ranking
    update_ranking
  end

  def update_ranking
    return unless challenge.submissions.any?
    
    ranked_submissions = challenge.submissions.order(score: :desc, submitted_at: :asc).to_a
    ranked_submissions.each_with_index do |submission, index|
      submission.update_column(:rank, index + 1) if submission.persisted?
    end
  end

  private

  def challenge_not_closed
    return unless challenge
    if challenge.completed? && status == "joined" && recipe_id.nil?
      errors.add(:base, "Challenge-ul s-a încheiat")
    end
  end

  def increment_participants_count
    challenge.increment!(:participants_count) unless challenge.participants_count_changed?
  end

  def increment_submissions_count
    if status == "submitted" && status_was != "submitted"
      challenge.increment!(:submissions_count)
    end
  end
end

