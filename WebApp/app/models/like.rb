class Like < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, counter_cache: true
  validates :user_id, uniqueness: { scope: :recipe_id }
  
  after_create_commit :create_notification, if: -> { recipe.user.present? && recipe.user != user }
  
  private
  
  def create_notification
    Notification.create!(
      user: recipe.user,
      notification_type: 'like',
      title: I18n.t('notifications.like.title'),
      message: I18n.t('notifications.like.body', user: user.username, recipe: recipe.title),
      recipe: recipe
    )
  end
end
