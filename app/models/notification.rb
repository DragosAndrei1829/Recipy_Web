class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, optional: true

  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }

  NOTIFICATION_TYPES = %w[comment like follow message recipe_shared recipe_quarantined recipe_released recipe_removed user_blocked user_unblocked].freeze

  validates :notification_type, inclusion: { in: NOTIFICATION_TYPES }

  def mark_as_read!
    update(read: true)
  end

  def icon
    case notification_type
    when "comment"
      "💬"
    when "like"
      "❤️"
    when "follow"
      "👤"
    when "message"
      "✉️"
    when "recipe_shared"
      "📤"
    when "recipe_quarantined"
      "⚠️"
    when "recipe_released"
      "✅"
    when "recipe_removed"
      "🗑️"
    when "user_blocked"
      "🚫"
    when "user_unblocked"
      "✅"
    else
      "🔔"
    end
  end
end
