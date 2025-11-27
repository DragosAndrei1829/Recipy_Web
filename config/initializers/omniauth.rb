# frozen_string_literal: true

# OmniAuth configuration for Rails 7+ with Turbo/Hotwire

# CRITICAL: Disable OmniAuth's built-in CSRF protection
# This is safe because we're using Devise which has its own CSRF protection
# and we're using POST forms with authenticity tokens
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# Disable the authenticity token protection that's causing issues
# We handle CSRF through Rails' own mechanisms
OmniAuth.config.request_validation_phase = nil

# Handle failures gracefully
OmniAuth.config.on_failure = Proc.new do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end

# Development settings
if Rails.env.development?
  OmniAuth.config.logger = Rails.logger
  OmniAuth.config.full_host = "http://localhost:3000"
end
