# frozen_string_literal: true

class GroupMessage < ApplicationRecord
  belongs_to :group
  belongs_to :user

  validates :content, presence: true, length: { maximum: 2000 }

  scope :recent, -> { order(created_at: :desc) }

  # Broadcast to group members via Turbo Streams
  after_create_commit :broadcast_to_group

  private

  def broadcast_to_group
    broadcast_append_to(
      "group_#{group_id}_messages",
      target: "group-messages",
      partial: "groups/message",
      locals: { message: self }
    )
  end
end
