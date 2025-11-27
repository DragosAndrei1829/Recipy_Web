# frozen_string_literal: true

class GroupRecipe < ApplicationRecord
  belongs_to :group, counter_cache: :recipes_count
  belongs_to :recipe
  belongs_to :added_by, class_name: "User"

  validates :recipe_id, uniqueness: { scope: :group_id, message: "este deja în acest grup" }
  validates :note, length: { maximum: 500 }

  scope :recent, -> { order(created_at: :desc) }
end
