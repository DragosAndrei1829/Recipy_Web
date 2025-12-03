# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :user

  # Plan types
  PLAN_AI_CHAT = 'ai_chat'

  # Status values
  STATUS_ACTIVE = 'active'
  STATUS_CANCELED = 'canceled'
  STATUS_PAST_DUE = 'past_due'
  STATUS_UNPAID = 'unpaid'
  STATUS_INCOMPLETE = 'incomplete'
  STATUS_TRIALING = 'trialing'

  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :status, presence: true
  validates :plan_type, presence: true

  scope :active, -> { where(status: STATUS_ACTIVE) }
  scope :for_plan, ->(plan_type) { where(plan_type: plan_type) }

  def active?
    status == STATUS_ACTIVE && current_period_end > Time.current
  end

  def expired?
    current_period_end < Time.current
  end

  def canceled?
    status == STATUS_CANCELED || canceled_at.present?
  end
end
