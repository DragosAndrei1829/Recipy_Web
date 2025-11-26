class FoodType < ApplicationRecord
  has_many :recipes

  def display_name
    I18n.t("food_types.#{name.parameterize.underscore}", default: name)
  end
end
