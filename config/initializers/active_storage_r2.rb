# Active Storage R2 Configuration
# This ensures R2 URLs are generated correctly with proper signed URLs

Rails.application.config.after_initialize do
  if Rails.env.production?
    # Log R2 configuration
    if ENV['AWS_ENDPOINT'].present?
      Rails.logger.info "R2 Configuration: Endpoint=#{ENV['AWS_ENDPOINT']}, Bucket=#{ENV['AWS_S3_BUCKET']}"
    end

    # Ensure signed URLs work correctly for R2
    ActiveStorage::Service::S3Service.class_eval do
      def url(key, expires_in:, filename:, disposition:, content_type:)
        begin
          # For R2, we need to use presigned URLs
          object = object_for(key)
          
          # Check if object exists
          unless object.exists?
            Rails.logger.warn "R2 object not found: #{key}"
            return nil
          end

          # Generate presigned URL with proper expiration (default 1 hour)
          presigned_url = object.presigned_url(
            :get,
            expires_in: expires_in || 3600,
            response_content_disposition: content_disposition_with(type: content_type, filename: filename),
            response_content_type: content_type
          )

          Rails.logger.debug "Generated R2 signed URL for #{key}: #{presigned_url[0..100]}..."
          presigned_url
        rescue Aws::S3::Errors::NoSuchKey => e
          Rails.logger.error "R2 object not found: #{key} - #{e.message}"
          nil
        rescue => e
          Rails.logger.error "Error generating R2 signed URL for key #{key}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          nil
        end
      end
    end
  end
end

