# frozen_string_literal: true

class Collection < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :collection_recipes, dependent: :destroy
  has_many :recipes, through: :collection_recipes, source: :recipe
  has_one_attached :cover_image

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 1000 }
  validates :name, uniqueness: { scope: :user_id, message: "ai deja o colecție cu acest nume" }
  validate :cover_image_format_and_size

  # Scopes
  scope :public_collections, -> { where(is_public: true) }
  scope :private_collections, -> { where(is_public: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :most_recipes, -> { order(recipes_count: :desc) }

  # Callbacks
  before_validation :set_default_position_for_recipes, on: :update

  # Methods
  def add_recipe(recipe, note: nil)
    return false if recipes.include?(recipe)
    
    max_position = collection_recipes.maximum(:position) || -1
    collection_recipes.create!(
      recipe: recipe,
      position: max_position + 1,
      note: note
    )
    increment!(:recipes_count)
    true
  end

  def remove_recipe(recipe)
    collection_recipe = collection_recipes.find_by(recipe: recipe)
    return false unless collection_recipe
    
    collection_recipe.destroy
    decrement!(:recipes_count)
    true
  end

  def reorder_recipes(recipe_ids)
    recipe_ids.each_with_index do |recipe_id, index|
      collection_recipes.find_by(recipe_id: recipe_id)&.update(position: index)
    end
  end

  def viewable_by?(viewer)
    return true if user == viewer
    return true if is_public?
    false
  end

  def owned_by?(owner)
    user == owner
  end

  private

  def cover_image_format_and_size
    if cover_image.attached?
      unless cover_image.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
        errors.add(:cover_image, "trebuie să fie un fișier JPEG, PNG, GIF sau WebP")
      end
      if cover_image.byte_size > 5.megabytes
        errors.add(:cover_image, "nu poate fi mai mare de 5MB")
      end
    end
  end

  def set_default_position_for_recipes
    collection_recipes.where(position: nil).each_with_index do |cr, index|
      cr.update_column(:position, index)
    end
  end
end




