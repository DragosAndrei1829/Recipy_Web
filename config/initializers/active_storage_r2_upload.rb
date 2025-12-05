# Active Storage R2 Upload Configuration
# Uses the same logic as test_r2_upload.rb which works correctly
# Direct S3 client calls with put_object (no checksums, no metadata)

Rails.application.config.after_initialize do
  if ENV['AWS_ENDPOINT'].present? && defined?(ActiveStorage::Service::S3Service)
    begin
      # Override the upload method to use direct S3 client calls (like test_r2_upload.rb)
      ActiveStorage::Service::S3Service.class_eval do
        alias_method :original_upload, :upload
        
        def upload(key, io, checksum: nil, **options)
          begin
            # Use direct S3 client call exactly like test_r2_upload.rb
            # Get the client from the resource (same as test script)
            s3_client = bucket.client
            
            # Read the IO stream
            body = io.read
            io.rewind if io.respond_to?(:rewind)
            
            # Upload using put_object (exactly like test_r2_upload.rb)
            s3_client.put_object(
              bucket: bucket.name,
              key: key,
              body: body,
              content_type: options[:content_type] || 'application/octet-stream'
            )
            
            Rails.logger.debug "R2 upload successful for key: #{key[0..50]}... (using direct put_object)"
            # Return a hash that Active Storage expects
            { etag: nil }
          rescue => e
            Rails.logger.error "R2 upload failed for key #{key[0..50]}...: #{e.message}"
            Rails.logger.error e.backtrace.first(5).join("\n")
            raise
          end
        end
      end
    rescue => e
      Rails.logger.warn "Could not configure R2 upload: #{e.message}"
      Rails.logger.error e.backtrace.first(3).join("\n")
    end
  end
end

