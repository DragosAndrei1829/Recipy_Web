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
end
