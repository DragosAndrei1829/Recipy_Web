# Active Storage R2 Upload Configuration
# Fixes "You can only specify one non-default checksum at a time" error
# R2 doesn't support multiple checksum algorithms simultaneously

Rails.application.config.after_initialize do
  if Rails.env.production? && ENV['AWS_ENDPOINT'].present? && defined?(ActiveStorage::Service::S3Service)
    begin
      # Override the upload method to prevent checksum conflicts
      ActiveStorage::Service::S3Service.class_eval do
        alias_method :original_upload, :upload
        
        def upload(key, io, checksum: nil, **options)
          begin
            # Remove all checksum-related options to avoid R2 conflicts
            clean_options = options.dup
            clean_options.delete(:checksum_algorithm)
            clean_options.delete(:content_md5)
            clean_options.delete(:content_md5_base64)
            clean_options.delete(:metadata)
            
            # Upload without checksum
            result = original_upload(key, io, checksum: nil, **clean_options)
            Rails.logger.debug "R2 upload successful for key: #{key[0..50]}..."
            result
          rescue Aws::S3::Errors::InvalidRequest => e
            if e.message.include?("checksum") || e.message.include?("Checksum") || e.message.include?("non-default checksum")
              Rails.logger.error "R2 checksum conflict for key #{key[0..50]}...: #{e.message}"
              Rails.logger.warn "Retrying upload without any checksum parameters..."
              
              # Force upload without any checksum-related parameters
              # Use direct S3 client call to bypass Active Storage checksum logic
              begin
                object = object_for(key)
                object.upload_stream(io, content_type: options[:content_type] || 'application/octet-stream')
                Rails.logger.info "R2 upload successful (retry) for key: #{key[0..50]}..."
              rescue => retry_error
                Rails.logger.error "R2 upload retry failed: #{retry_error.message}"
                raise e # Raise original error
              end
            else
              raise
            end
          end
        end
      end
    rescue => e
      Rails.logger.warn "Could not configure R2 upload: #{e.message}"
    end
  end
end

