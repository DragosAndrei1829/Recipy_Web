class Conversation < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  has_many :messages, dependent: :destroy
  has_many :shared_recipes, dependent: :destroy

  validate :unique_conversation

  def unique_conversation
    existing = Conversation.between(sender, recipient).where.not(id: id).first
    if existing
      errors.add(:base, "Conversation already exists")
    end
  end

  scope :between, ->(user1, user2) {
    where(sender: user1, recipient: user2).or(
      where(sender: user2, recipient: user1)
    )
  }

  scope :for_user, ->(user) {
    where(sender: user).or(where(recipient: user))
  }

  def other_user(current_user)
    sender == current_user ? recipient : sender
  end

  def unread_messages_count_for(user)
    messages.where.not(user: user).where(read: false).count
  end

  # Get all conversation items (messages and shared recipes) sorted by created_at
  def conversation_items
    items = []
    messages.each { |m| items << { type: :message, item: m, created_at: m.created_at } }
    shared_recipes.each { |sr| items << { type: :shared_recipe, item: sr, created_at: sr.created_at } }
    items.sort_by { |i| i[:created_at] }
  end
end
