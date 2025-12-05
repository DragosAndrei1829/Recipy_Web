module ApplicationHelper
  def google_oauth_configured?
    ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  end

  def apple_oauth_configured?
    ENV["APPLE_CLIENT_ID"].present? &&
    ENV["APPLE_CLIENT_SECRET"].present? &&
    ENV["APPLE_TEAM_ID"].present? &&
    ENV["APPLE_KEY_ID"].present? &&
    ENV["APPLE_PRIVATE_KEY"].present?
  end

  # Helper to get image URL without variants (R2 doesn't support variants)
  # Use CSS for sizing instead
  def image_url_without_variant(attachment, size: nil)
    return nil unless attachment&.attached?
    
    begin
      url_for(attachment)
    rescue => e
      Rails.logger.error "Error generating image URL: #{e.message}"
      nil
    end
  end
end
