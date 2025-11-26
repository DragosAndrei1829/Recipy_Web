class Category < ApplicationRecord
  has_many :recipes

  def display_name
    I18n.t("categories.#{name.parameterize.underscore}", default: name)
  end
end
