# frozen_string_literal: true

class CollectionRecipe < ApplicationRecord
  # Associations
  belongs_to :collection, counter_cache: :recipes_count
  belongs_to :recipe

  # Validations
  validates :recipe_id, uniqueness: { scope: :collection_id, message: "este deja în această colecție" }
  validates :note, length: { maximum: 500 }

  # Scopes
  scope :ordered, -> { order(:position, :created_at) }

  # Callbacks
  before_create :set_default_position

  private

  def set_default_position
    self.position ||= (collection.collection_recipes.maximum(:position) || -1) + 1
  end
end

