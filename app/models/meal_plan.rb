# frozen_string_literal: true

class MealPlan < ApplicationRecord
  belongs_to :user
  belongs_to :recipe

  MEAL_TYPES = %w[breakfast lunch dinner snack].freeze

  validates :meal_type, presence: true, inclusion: { in: MEAL_TYPES }
  validates :planned_for, presence: true
  validates :servings, presence: true, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: [:recipe_id, :planned_for, :meal_type], message: "Această rețetă este deja planificată pentru această masă" }

  scope :for_date, ->(date) { where(planned_for: date) }
  scope :for_week, ->(start_date) { where(planned_for: start_date..(start_date + 6.days)) }
  scope :upcoming, -> { where("planned_for >= ?", Date.current) }
  scope :by_meal_type, ->(type) { where(meal_type: type) }

  def self.for_user_and_date_range(user, start_date, end_date)
    where(user: user, planned_for: start_date..end_date).order(:planned_for, :meal_type)
  end
end




