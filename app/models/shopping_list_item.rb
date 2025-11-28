# frozen_string_literal: true

class ShoppingListItem < ApplicationRecord
  belongs_to :shopping_list, counter_cache: :items_count
  belongs_to :recipe, optional: true

  validates :ingredient_name, presence: true
  validates :position, presence: true

  scope :checked, -> { where(checked: true) }
  scope :unchecked, -> { where(checked: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :ordered, -> { order(:position, :category, :ingredient_name) }

  after_update :update_checked_count, if: :saved_change_to_checked?

  def toggle_checked!
    update!(checked: !checked)
  end

  private

  def update_checked_count
    if checked?
      shopping_list.increment!(:checked_items_count)
    else
      shopping_list.decrement!(:checked_items_count) if shopping_list.checked_items_count > 0
    end
  end
end

