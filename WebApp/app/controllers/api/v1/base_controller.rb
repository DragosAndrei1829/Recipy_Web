module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::MimeResponds

      before_action :authenticate_api_user!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from JWT::DecodeError, with: :unauthorized
      rescue_from JWT::ExpiredSignature, with: :token_expired

      private

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

