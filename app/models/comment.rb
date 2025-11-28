class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, counter_cache: true
  has_many :review_helpfuls, dependent: :destroy
  has_many :helpful_users, through: :review_helpfuls, source: :user

  validates :body,
            presence: { message: I18n.t("activerecord.errors.models.comment.attributes.body.blank", default: "Comentariul nu poate fi gol") },
            unless: :rating_present?
  validates :body, length: { maximum: 2000 }, allow_blank: true
  validates :rating,
            numericality: {
              allow_nil: true,
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 10,
              message: I18n.t("activerecord.errors.models.comment.attributes.rating.invalid", default: "Rating-ul trebuie să fie între 0 și 10")
            }
  
  # Advanced ratings validation
  validates :taste_rating,
            numericality: {
              allow_nil: true,
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 5,
              message: "Rating-ul pentru gust trebuie să fie între 1 și 5"
            }
  validates :difficulty_rating,
            numericality: {
              allow_nil: true,
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 5,
              message: "Rating-ul pentru dificultate trebuie să fie între 1 și 5"
            }
  validates :time_rating,
            numericality: {
              allow_nil: true,
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 5,
              message: "Rating-ul pentru timp trebuie să fie între 1 și 5"
            }
  validates :cost_rating,
            numericality: {
              allow_nil: true,
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 5,
              message: "Rating-ul pentru cost trebuie să fie între 1 și 5"
            }

  after_create_commit :create_notification, if: -> { recipe.user.present? && recipe.user != user }
  after_save :update_recipe_ratings, if: :saved_change_to_rating?

  scope :with_ratings, -> { where.not(rating: nil) }
  scope :helpful, -> { order(helpful_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :highest_rated, -> { order(rating: :desc) }

  def rating_present?
    rating.present? || taste_rating.present? || difficulty_rating.present? || time_rating.present? || cost_rating.present?
  end

  def has_advanced_ratings?
    taste_rating.present? || difficulty_rating.present? || time_rating.present? || cost_rating.present?
  end

  def average_advanced_rating
    ratings = [taste_rating, difficulty_rating, time_rating, cost_rating].compact
    return nil if ratings.empty?
    (ratings.sum.to_f / ratings.size).round(1)
  end

  def helpful_by?(user)
    return false unless user
    review_helpfuls.exists?(user: user)
  end

  private

  def create_notification
    Notification.create!(
      user: recipe.user,
      notification_type: "comment",
      title: I18n.t("notifications.comment.title"),
      message: I18n.t("notifications.comment.body", user: user.username, recipe: recipe.title, preview: body.presence || I18n.t("comments.rating_only")),
      recipe: recipe
    )
  end

  def update_recipe_ratings
    recipe.update_average_rating if recipe.respond_to?(:update_average_rating)
  end
end

