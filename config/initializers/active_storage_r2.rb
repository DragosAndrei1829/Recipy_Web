# Active Storage R2 Configuration
# This ensures R2 URLs are generated correctly
# With Public Access enabled, we can use public URLs directly (faster and simpler)

Rails.application.config.after_initialize do
  if Rails.env.production? && defined?(ActiveStorage::Service::S3Service)
    # Log R2 configuration
    if ENV['AWS_ENDPOINT'].present?
      Rails.logger.info "R2 Configuration: Endpoint=#{ENV['AWS_ENDPOINT']}, Bucket=#{ENV['AWS_S3_BUCKET']}"
      Rails.logger.info "R2 Public Domain: https://pub-74a98915f906497b8868c50e202895bc.r2.dev"
    end

    # Use public URLs if public access is enabled, otherwise use signed URLs
    begin
      ActiveStorage::Service::S3Service.class_eval do
        def url(key, expires_in:, filename:, disposition:, content_type:)
          begin
            # Check if we should use public URLs (if R2_PUBLIC_DOMAIN is set)
            public_domain = ENV['R2_PUBLIC_DOMAIN']
            
            if public_domain.present?
              # Use public URL directly (faster, no expiration)
              # R2 public domain format: https://pub-xxx.r2.dev/key (bucket is already associated with domain)
              # Try without bucket first, then with bucket if needed
              public_url = "#{public_domain}/#{key}"
              Rails.logger.info "Using R2 public URL (format 1): #{public_url}"
              return public_url
            end

            # Otherwise, use presigned URLs (for private buckets)
            object = object_for(key)
            
            # Generate presigned URL with proper expiration (default 1 hour)
            presigned_url = object.presigned_url(
              :get,
              expires_in: expires_in || 3600,
              response_content_disposition: content_disposition_with(type: content_type, filename: filename),
              response_content_type: content_type
            )

            Rails.logger.debug "Generated R2 signed URL for #{key}"
            presigned_url
          rescue Aws::S3::Errors::NoSuchKey => e
            Rails.logger.error "R2 object not found: #{key} - #{e.message}"
            nil
          rescue => e
            Rails.logger.error "Error generating R2 URL for key #{key}: #{e.message}"
            Rails.logger.error e.backtrace.first(5).join("\n")
            nil
          end
        end
      end
    rescue => e
      Rails.logger.warn "Could not configure R2 URL generation: #{e.message}"
    end
  end
end

