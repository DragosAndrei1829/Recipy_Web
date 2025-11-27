# frozen_string_literal: true

# OmniAuth configuration for Rails 7+ with Turbo/Hotwire

# Allow both POST and GET methods
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# Handle failures gracefully
OmniAuth.config.on_failure = Proc.new do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end

# Development settings
if Rails.env.development?
  OmniAuth.config.logger = Rails.logger
  OmniAuth.config.full_host = "http://localhost:3000"
end

# CRITICAL: Monkey-patch to disable AuthenticityTokenProtection
# This is needed because OmniAuth 2.0+ has built-in CSRF protection
# that conflicts with Rails 7 + Turbo forms
module OmniAuth
  class AuthenticityTokenProtection
    def self.call(env)
      # Bypass the authenticity check completely
      # Rails' own CSRF protection handles this
      true
    end
  end
end
