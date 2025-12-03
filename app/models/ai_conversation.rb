class AiConversation < ApplicationRecord
  belongs_to :user
  
  validates :title, presence: true
  validates :provider, presence: true
  
  # Automatically set title from first message
  before_validation :set_title_from_messages, on: :create, if: -> { title.blank? && messages.present? }
  
  # Update last_message_at on save
  before_save :update_last_message_at
  
  scope :recent, -> { order(last_message_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  
  def add_message(role, content)
    self.messages ||= []
    self.messages << { role: role, content: content, timestamp: Time.current.iso8601 }
    self.last_message_at = Time.current
    save
  end
  
  def last_user_message
    messages&.reverse&.find { |m| m["role"] == "user" }&.dig("content")
  end
  
  private
  
  def set_title_from_messages
    if messages.is_a?(Array) && messages.any?
      first_user_msg = messages.find { |m| m["role"] == "user" }
      self.title = first_user_msg["content"]&.truncate(50) if first_user_msg
    end
    self.title ||= "Conversație AI"
  end
  
  def update_last_message_at
    self.last_message_at = Time.current if messages_changed?
  end
end
