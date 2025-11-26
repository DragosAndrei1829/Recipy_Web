class SharedRecipe < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :recipe
  belongs_to :conversation

  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :create_notification

  def mark_as_read!
    update(read: true)
  end

  private

  def create_notification
    Notification.create!(
      user: recipient,
      notification_type: "recipe_shared",
      title: I18n.t("notifications.recipe_shared.title"),
      message: I18n.t("notifications.recipe_shared.body", sender: sender.username, recipe: recipe.title),
      recipe: recipe
    )
  end
end
