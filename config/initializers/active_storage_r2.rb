# Active Storage R2 Configuration
# This ensures R2 URLs are generated correctly
# Using signed URLs since public URLs return 404

Rails.application.config.after_initialize do
  if Rails.env.production? && defined?(ActiveStorage::Service::S3Service)
    # Log R2 configuration
    if ENV['AWS_ENDPOINT'].present?
      Rails.logger.info "R2 Configuration: Endpoint=#{ENV['AWS_ENDPOINT']}, Bucket=#{ENV['AWS_S3_BUCKET']}"
    end

    # Use signed URLs (public URLs don't work - return 404)
    begin
      ActiveStorage::Service::S3Service.class_eval do
        def url(key, expires_in:, filename:, disposition:, content_type:)
          begin
            # Always use presigned URLs for R2 (public URLs return 404)
            object = object_for(key)
            
            # Generate presigned URL with proper expiration (default 1 hour)
            presigned_url = object.presigned_url(
              :get,
              expires_in: expires_in || 3600,
              response_content_disposition: content_disposition_with(type: content_type, filename: filename),
              response_content_type: content_type
            )

            Rails.logger.debug "Generated R2 signed URL for #{key[0..50]}..."
            presigned_url
          rescue Aws::S3::Errors::NoSuchKey => e
            Rails.logger.error "R2 object not found: #{key[0..50]}... - #{e.message}"
            # Raise exception instead of returning nil - Active Storage will handle it
            raise ActiveStorage::FileNotFoundError, "R2 object not found: #{key}"
          rescue => e
            Rails.logger.error "Error generating R2 URL for key #{key[0..50]}...: #{e.message}"
            Rails.logger.error e.backtrace.first(5).join("\n")
            # Raise exception - Active Storage will handle it gracefully
            raise ActiveStorage::FileNotFoundError, "Error generating R2 URL: #{e.message}"
          end
        end
      end
    rescue => e
      Rails.logger.warn "Could not configure R2 URL generation: #{e.message}"
    end
  end
end

