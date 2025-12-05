# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data, "https://fonts.gstatic.com", "https://fonts.googleapis.com"
    policy.img_src     :self, :https, :data, :blob,
                       "https://*.blob.core.windows.net",  # Azure Storage
                       "https://*.amazonaws.com",          # AWS S3
                       "https://*.r2.dev",                 # Cloudflare R2 Public Domain
                       "https://*.r2.cloudflarestorage.com", # Cloudflare R2 S3 API
                       "https://lh3.googleusercontent.com", # Google profile images
                       "https://avatars.githubusercontent.com"
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline, :unsafe_eval  # Required for Turbo/Stimulus
    policy.style_src   :self, :https, :unsafe_inline, "https://fonts.googleapis.com"
    policy.connect_src :self, :https,
                       "wss://#{Rails.application.config.action_cable.url || 'localhost:3000'}",  # ActionCable WebSocket
                       "https://*.blob.core.windows.net",
                       "https://*.amazonaws.com",
                       "https://*.r2.dev",                 # Cloudflare R2 Public Domain
                       "https://*.r2.cloudflarestorage.com" # Cloudflare R2 S3 API
    policy.frame_ancestors :self
    policy.base_uri    :self
    policy.form_action :self, :https,
                       "https://accounts.google.com",  # OAuth
                       "https://appleid.apple.com"

    # Specify URI for violation reports (optional - uncomment to enable)
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  # Note: This requires changes to how scripts/styles are included
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy (good for testing).
  # Set to false in production after testing
  config.content_security_policy_report_only = Rails.env.development?
end

# Additional security headers (set in application.rb or via middleware)
# These are commonly set but Rails handles some automatically:
# - X-Frame-Options: SAMEORIGIN (Rails default)
# - X-XSS-Protection: 0 (deprecated, CSP is better)
# - X-Content-Type-Options: nosniff (Rails default)
# - X-Download-Options: noopen (Rails default)
# - X-Permitted-Cross-Domain-Policies: none (Rails default)
# - Referrer-Policy: strict-origin-when-cross-origin (Rails default)
