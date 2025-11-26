class SiteSetting < ApplicationRecord
  belongs_to :theme, optional: true

  # Singleton pattern - only one record should exist
  def self.instance
    # Always fetch fresh from database, no caching
    setting = first_or_create! do |s|
      s.contact_email = "contact@recipy.com"
      s.contact_phone = "+40 XXX XXX XXX"
      s.contact_address = "Address will be added here"
      s.theme = Theme.default
    end
    # Always reload to get fresh data
    setting.reload
    setting
  end

  def current_theme
    theme || Theme.default
  end
end
