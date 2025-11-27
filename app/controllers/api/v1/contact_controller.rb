module Api
  module V1
    class ContactController < BaseController
      skip_before_action :authenticate_api_user!, only: [:create]

      def create
        # Validate required fields
        required_fields = [:name, :email, :category, :subject, :message]
        missing_fields = required_fields.select { |f| params[f].blank? }
        
        if missing_fields.any?
          return render json: {
            success: false,
            error: "Missing required fields: #{missing_fields.join(', ')}"
          }, status: :unprocessable_entity
        end

        # Validate email format
        unless params[:email] =~ URI::MailTo::EMAIL_REGEXP
          return render json: {
            success: false,
            error: "Invalid email format"
          }, status: :unprocessable_entity
        end

        begin
          # Send the support email
          ContactMailer.support_message(
            name: params[:name],
            email: params[:email],
            category: params[:category],
            subject: params[:subject],
            message: params[:message]
          ).deliver_now

          render json: {
            success: true,
            message: "Message sent successfully. We will respond within 24 hours."
          }, status: :ok
        rescue StandardError => e
          Rails.logger.error "Contact form error: #{e.message}"
          render json: {
            success: false,
            error: "Failed to send message. Please try again later."
          }, status: :internal_server_error
        end
      end
    end
  end
end

