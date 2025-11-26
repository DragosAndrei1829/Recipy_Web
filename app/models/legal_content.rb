class LegalContent < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :title_ro, presence: true
  validates :content_ro, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(section_order: :asc) }

  # Get title in current locale
  def title(locale = I18n.locale)
    locale.to_s == "en" ? (title_en.presence || title_ro) : title_ro
  end

  # Get content in current locale
  def content(locale = I18n.locale)
    locale.to_s == "en" ? (content_en.presence || content_ro) : content_ro
  end

  # Find content by key for a page (e.g., 'privacy', 'terms', 'cookies')
  def self.for_page(page_key)
    active.where("key LIKE ?", "#{page_key}_%").ordered
  end

  # Get single section
  def self.section(key)
    find_by(key: key, active: true)
  end

  # Check if content exists for a page
  def self.has_content?(page_key)
    for_page(page_key).exists?
  end
end
