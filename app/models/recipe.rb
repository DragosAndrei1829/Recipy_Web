class Recipe < ApplicationRecord
  has_many :notifications, dependent: :destroy
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :cuisine, optional: true
  belongs_to :food_type, optional: true
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :collection_recipes, dependent: :destroy
  has_many :collections, through: :collection_recipes
  has_many :reports, as: :reportable, dependent: :destroy
  has_many :video_timestamps, dependent: :destroy
  has_many :live_sessions, dependent: :destroy
  has_one_attached :video
  has_many_attached :photos

  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :ingredients, presence: true, length: { minimum: 10 }
  validates :preparation, presence: true, length: { minimum: 10 }
  
  # Slug generation
  before_validation :generate_slug, on: :create
  before_validation :regenerate_slug, on: :update, if: :title_changed?
  
  # Video validation - max 100MB, only video formats
  validate :video_format_and_size
  
  def to_param
    slug.presence || id.to_s
  end

  # Moderation scopes
  scope :visible, -> { where(quarantined: false) }
  scope :quarantined, -> { where(quarantined: true) }
  scope :with_reports, -> { where('reports_count > 0') }

  # Quarantine a recipe
  def quarantine!(reason = nil)
    update!(
      quarantined: true,
      quarantined_at: Time.current,
      quarantine_reason: reason
    )
  end

  # Release from quarantine
  def release_from_quarantine!
    update!(
      quarantined: false,
      quarantined_at: nil,
      quarantine_reason: nil
    )
    # Mark all pending reports as resolved
    reports.pending_review.update_all(status: :resolved_invalid)
  end

  # Check if visible to user
  def visible_to?(viewer)
    return true unless quarantined?
    return true if viewer&.admin?
    return true if viewer == user # Owner can see their own quarantined recipes
    false
  end

  def video_format_and_size
    return unless video.attached?
    
    # Check file size (max 100MB)
    if video.blob.byte_size > 100.megabytes
      errors.add(:video, "is too large (maximum is 100MB)")
      video.purge
    end
    
    # Check content type
    acceptable_types = ['video/mp4', 'video/quicktime', 'video/webm', 'video/x-msvideo', 'video/x-matroska']
    unless acceptable_types.include?(video.blob.content_type)
      errors.add(:video, "must be a video file (MP4, MOV, WebM, AVI, MKV)")
      video.purge
    end
  end

  def ordered_photos
    return photos if photos_order.blank?
    ids = photos.map(&:id).map(&:to_i)
    ordered = Array(photos_order).map(&:to_i) & ids
    photos.sort_by { |p| ordered.index(p.id) || photos.size }
  end
  def cover_photo
    return photos.find { |p| p.id == cover_photo_id } if cover_photo_id.present?
    ordered_photos.first
  end

  # Top recipes scopes
  scope :top_by_likes, -> { order(likes_count: :desc) }
  scope :created_today, -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :created_this_week, -> { where(created_at: Time.current.beginning_of_week..Time.current.end_of_week) }
  scope :created_this_month, -> { where(created_at: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :created_this_year, -> { where(created_at: Time.current.beginning_of_year..Time.current.end_of_year) }

  def self.top_of_day(limit = 10)
    created_today.top_by_likes.limit(limit)
  end

  def self.top_of_week(limit = 10)
    created_this_week.top_by_likes.limit(limit)
  end

  def self.top_of_month(limit = 10)
    created_this_month.top_by_likes.limit(limit)
  end

  def self.top_of_year(limit = 10)
    created_this_year.top_by_likes.limit(limit)
  end

  # Calculate and update average rating from comments
  def update_average_rating
    ratings = comments.where.not(rating: nil).pluck(:rating)
    return if ratings.empty?
    
    avg_rating = (ratings.sum.to_f / ratings.size).round(1)
    update_column(:rating, avg_rating) if respond_to?(:rating)
  end

  # Get average advanced ratings
  def average_taste_rating
    ratings = comments.where.not(taste_rating: nil).pluck(:taste_rating)
    return nil if ratings.empty?
    (ratings.sum.to_f / ratings.size).round(1)
  end

  def average_difficulty_rating
    ratings = comments.where.not(difficulty_rating: nil).pluck(:difficulty_rating)
    return nil if ratings.empty?
    (ratings.sum.to_f / ratings.size).round(1)
  end

  def average_time_rating
    ratings = comments.where.not(time_rating: nil).pluck(:time_rating)
    return nil if ratings.empty?
    (ratings.sum.to_f / ratings.size).round(1)
  end

  def average_cost_rating
    ratings = comments.where.not(cost_rating: nil).pluck(:cost_rating)
    return nil if ratings.empty?
    (ratings.sum.to_f / ratings.size).round(1)
  end

  private

  def generate_slug
    return if slug.present?
    self.slug = title.parameterize if title.present?
    # Ensure uniqueness
    if slug.present? && Recipe.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{slug}-#{SecureRandom.hex(4)}"
    end
  end

  def regenerate_slug
    return unless title_changed?
    self.slug = title.parameterize if title.present?
    # Ensure uniqueness
    if slug.present? && Recipe.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{slug}-#{SecureRandom.hex(4)}"
    end
  end
end
