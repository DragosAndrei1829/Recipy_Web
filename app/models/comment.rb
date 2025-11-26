class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, counter_cache: true

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

  after_create_commit :create_notification, if: -> { recipe.user.present? && recipe.user != user }

  def rating_present?
    rating.present?
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
end
