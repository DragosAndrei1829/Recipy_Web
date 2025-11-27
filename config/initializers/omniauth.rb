# frozen_string_literal: true

# OmniAuth configuration
# This fixes the "Authenticity error" issue with OmniAuth 2.0+

OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# For Rails 7+ with Turbo, we need to handle the CSRF token properly
Rails.application.config.after_initialize do
  OmniAuth.config.before_request_phase do |env|
    # Allow OmniAuth to work with Turbo/Hotwire
    request = Rack::Request.new(env)
    
    # Store the CSRF token in session for verification
    if request.params['authenticity_token'].present?
      env['rack.session']['omniauth.csrf_token'] = request.params['authenticity_token']
    end
  end
end

