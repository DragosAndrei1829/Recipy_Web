class Cuisine < ApplicationRecord
  has_many :recipes

  def display_name
    I18n.t("cuisines.#{name.parameterize.underscore}", default: name)
  end
end
