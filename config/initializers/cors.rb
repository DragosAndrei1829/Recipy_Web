# Be sure to restart your server when you modify this file.

# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Development - Allow localhost for Flutter Web and local development
    if Rails.env.development?
      origins '*'
    else
      # Production - Specific origins only
      origins 'https://recipy-web.fly.dev',
              'https://www.recipy-web.fly.dev',
              /https:\/\/.*\.fly\.dev/,
              /http:\/\/localhost:\d+/,
              /http:\/\/127\.0\.0\.1:\d+/
    end

    # API endpoints
    resource '/api/v1/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false,
      expose: ['Authorization', 'X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-RateLimit-Reset'],
      max_age: 86400

    # ⚠️ IMPORTANT: Active Storage pentru imagini
    # Permite accesul la imaginile servite prin Active Storage
    resource '/rails/active_storage/*',
      headers: :any,
      methods: [:get, :options, :head],
      credentials: false,
      max_age: 86400
  end
end

