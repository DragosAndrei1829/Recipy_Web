# Rack::Attack configuration for rate limiting and brute force protection
# https://github.com/rack/rack-attack

class Rack::Attack
  ### Configure Cache ###
  # Use Rails cache for storing throttle data
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###
  # Block requests from a single IP that hit the app more than 300 times per 5 minutes
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  ### Prevent Brute-Force Login Attacks ###
  # Throttle POST requests to /users/sign_in by IP address
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /users/sign_in by email parameter
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalize email to prevent case-sensitivity bypass
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  ### Prevent Password Reset Spam ###
  throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  throttle("password_reset/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  ### Prevent Registration Spam ###
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/users" && req.post?
      req.ip
    end
  end

  ### API Rate Limiting (if you have API endpoints) ###
  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  ### Blocklist Bad IPs (optional - add IPs as needed) ###
  # blocklist("block bad IPs") do |req|
  #   ["1.2.3.4", "5.6.7.8"].include?(req.ip)
  # end

  ### Safelist Trusted IPs (optional) ###
  # safelist("allow from localhost") do |req|
  #   req.ip == "127.0.0.1" || req.ip == "::1"
  # end

  ### Custom Throttle Response ###
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ {
        error: "Rate limit exceeded. Please wait #{retry_after} seconds before retrying.",
        retry_after: retry_after
      }.to_json ]
    ]
  end
end

# Log blocked/throttled requests in development
if Rails.env.development?
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled #{req.ip} - #{req.path}"
  end
end
