class Follow < ApplicationRecord
  belongs_to :user
  belongs_to :follower, class_name: "User"

  validates :user_id, uniqueness: { scope: :follower_id }
  validate :cannot_follow_self

  after_create_commit :create_notification

  private

  def cannot_follow_self
    errors.add(:follower_id, "cannot follow yourself") if user_id == follower_id
  end

  def create_notification
    Notification.create!(
      user: user,
      notification_type: "follow",
      title: I18n.t("notifications.follow.title"),
      message: I18n.t("notifications.follow.body", user: follower.username)
    )
  end
end
