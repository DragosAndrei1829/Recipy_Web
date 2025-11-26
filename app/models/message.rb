class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  belongs_to :recipe, optional: true

  has_many_attached :images

  validates :body, presence: true, unless: -> { images.attached? || recipe_id.present? }
  validate :has_content

  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :create_notification
  # Broadcast handled via Turbo Streams in controller

  def mark_as_read!
    update(read: true)
  end

  def has_images?
    images.attached?
  end

  def has_recipe?
    recipe_id.present?
  end

  private

  def has_content
    unless body.present? || images.attached? || recipe_id.present?
      errors.add(:base, I18n.t("messages.must_have_content"))
    end
  end

  def create_notification
    recipient = conversation.other_user(user)
    preview = if recipe_id.present?
      I18n.t("notifications.message.recipe_shared", recipe: recipe.title)
    elsif images.attached?
      I18n.t("notifications.message.image_sent")
    else
      body.truncate(50)
    end

    Notification.create!(
      user: recipient,
      notification_type: "message",
      title: I18n.t("notifications.message.title"),
      message: I18n.t("notifications.message.body", sender: user.username, preview: preview)
    )
  end
end
