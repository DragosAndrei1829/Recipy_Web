module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::MimeResponds

      # Handle CORS preflight requests
      before_action :cors_preflight_check
      after_action :cors_set_access_control_headers

      before_action :authenticate_api_user!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from JWT::DecodeError, with: :unauthorized
      rescue_from JWT::ExpiredSignature, with: :token_expired

      private

      def cors_preflight_check
        if request.method == 'OPTIONS'
          headers['Access-Control-Allow-Origin'] = cors_allowed_origin
          headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, PATCH, DELETE, OPTIONS, HEAD'
          headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token, Authorization, Content-Type, Accept'
          headers['Access-Control-Max-Age'] = '86400'
          headers['Access-Control-Expose-Headers'] = 'Authorization, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset'
          render plain: '', content_type: 'text/plain'
        end
      end

      def cors_set_access_control_headers
        headers['Access-Control-Allow-Origin'] = cors_allowed_origin
        headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, PATCH, DELETE, OPTIONS, HEAD'
        headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token, Authorization, Content-Type, Accept'
        headers['Access-Control-Expose-Headers'] = 'Authorization, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset'
      end

      def cors_allowed_origin
        # In development, allow all origins
        return '*' if Rails.env.development?

        # In production, check against allowed origins
        origin = request.headers['Origin']
        allowed_origins = [
          'https://recipy-web.fly.dev',
          'https://www.recipy-web.fly.dev'
        ]

        # Allow localhost for testing
        if origin&.match?(/^https?:\/\/(localhost|127\.0\.0\.1):\d+$/)
          return origin
        end

        # Check if origin matches allowed list
        allowed_origins.include?(origin) ? origin : allowed_origins.first
      end

      def authenticate_api_user!
        @current_api_user = decode_token
        render_error("Unauthorized", :unauthorized) unless @current_api_user
      end

      def current_api_user
        @current_api_user
      end

      def decode_token
        header = request.headers["Authorization"]
        return nil unless header.present?

        token = header.split(" ").last
        decoded = JsonWebToken.decode(token)
        return nil unless decoded

        User.find_by(id: decoded[:user_id])
      rescue JWT::DecodeError, JWT::ExpiredSignature
        nil
      end

      def render_success(data, status = :ok)
        render json: { success: true, data: data }, status: status
      end

      def render_error(message, status = :unprocessable_entity)
        render json: { success: false, error: message }, status: status
      end

      def not_found
        render_error("Resource not found", :not_found)
      end

      def unprocessable_entity(exception)
        render_error(exception.record.errors.full_messages.join(", "), :unprocessable_entity)
      end

      def unauthorized
        render_error("Invalid token", :unauthorized)
      end

      def token_expired
        render_error("Token has expired", :unauthorized)
      end

      # Pagination helper
      def paginate(collection)
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 20).to_i
        per_page = [per_page, 100].min # Max 100 per page

        total = collection.count
        items = collection.offset((page - 1) * per_page).limit(per_page)

        {
          items: items,
          pagination: {
            current_page: page,
            per_page: per_page,
            total_items: total,
            total_pages: (total.to_f / per_page).ceil
          }
        }
      end
    end
  end
end

