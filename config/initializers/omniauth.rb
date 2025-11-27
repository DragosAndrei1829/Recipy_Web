# frozen_string_literal: true

# OmniAuth configuration for Rails 7+ with Turbo/Hotwire

# IMPORTANT: This fixes the "Authenticity error" with OmniAuth 2.0+
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# Handle failures gracefully
OmniAuth.config.on_failure = Proc.new do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end

# Log OmniAuth errors in development
if Rails.env.development?
  OmniAuth.config.logger = Rails.logger
  OmniAuth.config.full_host = "http://localhost:3000"
end
