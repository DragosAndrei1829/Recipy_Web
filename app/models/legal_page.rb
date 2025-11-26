# LegalPage - Stores full legal page content (Privacy, Terms, Cookies)
# Uses LegalContent table with page_type to distinguish full pages
class LegalPage
  PAGES = %w[privacy terms cookies].freeze

  def self.find_or_initialize(page_type)
    LegalContent.find_or_initialize_by(key: "page_#{page_type}", page_type: page_type)
  end

  def self.get(page_type, locale = I18n.locale)
    record = LegalContent.find_by(key: "page_#{page_type}", page_type: page_type)
    return nil unless record

    locale.to_s == "en" ? record.full_content_en : record.full_content_ro
  end

  def self.exists?(page_type)
    LegalContent.exists?(key: "page_#{page_type}", page_type: page_type)
  end

  def self.all_pages
    PAGES.map do |page_type|
      record = find_or_initialize(page_type)
      {
        type: page_type,
        title: page_title(page_type),
        has_content: record.persisted? && (record.full_content_ro.present? || record.full_content_en.present?),
        record: record
      }
    end
  end

  def self.page_title(page_type)
    case page_type
    when "privacy" then "Privacy Policy"
    when "terms" then "Terms & Conditions"
    when "cookies" then "Cookie Policy"
    else page_type.titleize
    end
  end

  def self.page_color(page_type)
    case page_type
    when "privacy" then "emerald"
    when "terms" then "blue"
    when "cookies" then "amber"
    else "gray"
    end
  end
end
