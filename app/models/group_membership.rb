# frozen_string_literal: true

class GroupMembership < ApplicationRecord
  belongs_to :group, counter_cache: :members_count
  belongs_to :user

  validates :role, presence: true, inclusion: { in: Group::ROLES }
  validates :user_id, uniqueness: { scope: :group_id, message: "este deja membru în acest grup" }

  scope :admins, -> { where(role: "admin") }
  scope :moderators, -> { where(role: %w[admin moderator]) }
  scope :members, -> { where(role: "member") }

  def admin?
    role == "admin"
  end

  def moderator?
    role.in?(%w[admin moderator])
  end
end
