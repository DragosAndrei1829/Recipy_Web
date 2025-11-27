# frozen_string_literal: true

# OmniAuth configuration for Rails 7+ with Turbo/Hotwire
# Fixes "Authenticity error" and CSRF issues

# Allow POST method (required for OmniAuth 2.0+)
OmniAuth.config.allowed_request_methods = [:post]

# Handle failures gracefully
OmniAuth.config.on_failure = Proc.new do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end

# Log OmniAuth errors in development
if Rails.env.development?
  OmniAuth.config.logger = Rails.logger
end
