# Active Storage R2 Configuration
# Uses the same logic as test_r2_upload.rb which works correctly
# Direct S3 client calls with presigned_url (exactly like test script)

module ActiveStorageR2UrlOverride
  def url(key, expires_in:, filename:, disposition:, content_type:)
    Rails.logger.debug "R2 url method called for key: #{key[0..50]}..."
    begin
      # Convert filename to ActiveStorage::Filename if it's a string
      # This prevents "undefined method `sanitized'" errors
      filename = ActiveStorage::Filename.new(filename) if filename.is_a?(String)
      
      # Use direct S3 client and presigner (like test_r2_upload.rb approach)
      s3_client = bucket.client
      
      # Use Aws::S3::Presigner to generate presigned URL
      signer = Aws::S3::Presigner.new(client: s3_client)
      presigned_url = signer.presigned_url(
        :get_object,
        bucket: bucket.name,
        key: key,
        expires_in: expires_in || 3600
      )

      Rails.logger.debug "Generated R2 signed URL for #{key[0..50]}... (using Presigner)"
      presigned_url
    rescue Aws::S3::Errors::NoSuchKey => e
      Rails.logger.warn "R2 object not found: #{key[0..50]}... - #{e.message}"
      # Return nil for missing objects - BlobsController will handle it
      nil
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "R2 service error for key #{key[0..50]}...: #{e.message}"
      Rails.logger.error e.backtrace.first(3).join("\n")
      nil
    rescue => e
      Rails.logger.error "Error generating R2 URL for key #{key[0..50]}...: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      nil
    end
  end
end

Rails.application.config.after_initialize do
  if ENV['AWS_ENDPOINT'].present? && defined?(ActiveStorage::Service::S3Service)
    # Log R2 configuration
    Rails.logger.info "R2 Configuration: Endpoint=#{ENV['AWS_ENDPOINT']}, Bucket=#{ENV['AWS_S3_BUCKET']}"

    # Override the url method using alias_method to ensure it's called
    begin
      ActiveStorage::Service::S3Service.class_eval do
        alias_method :original_url, :url unless method_defined?(:original_url)
        
        def url(key, expires_in:, filename:, disposition:, content_type:)
          Rails.logger.info "🔵 R2 url method INTERCEPTED for key: #{key[0..50]}..., filename class: #{filename.class}"
          # Convert filename to ActiveStorage::Filename if it's a string
          filename = ActiveStorage::Filename.new(filename) if filename.is_a?(String)
          Rails.logger.info "🔵 After conversion, filename class: #{filename.class}"
          begin
            # Use direct S3 client and presigner (like test_r2_upload.rb approach)
            s3_client = bucket.client
            
            # Use Aws::S3::Presigner to generate presigned URL
            signer = Aws::S3::Presigner.new(client: s3_client)
            presigned_url = signer.presigned_url(
              :get_object,
              bucket: bucket.name,
              key: key,
              expires_in: expires_in || 3600
            )

            Rails.logger.debug "Generated R2 signed URL for #{key[0..50]}... (using Presigner)"
            presigned_url
          rescue Aws::S3::Errors::NoSuchKey => e
            Rails.logger.warn "R2 object not found: #{key[0..50]}... - #{e.message}"
            nil
          rescue Aws::S3::Errors::ServiceError => e
            Rails.logger.error "R2 service error for key #{key[0..50]}...: #{e.message}"
            Rails.logger.error e.backtrace.first(3).join("\n")
            nil
          rescue => e
            Rails.logger.error "Error generating R2 URL for key #{key[0..50]}...: #{e.message}"
            Rails.logger.error e.backtrace.first(5).join("\n")
            nil
          end
        end
      end
      Rails.logger.info "R2 URL override method installed successfully"
    rescue => e
      Rails.logger.warn "Could not configure R2 URL generation: #{e.message}"
      Rails.logger.error e.backtrace.first(3).join("\n")
    end
  end
end

