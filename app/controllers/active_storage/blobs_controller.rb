# Override Active Storage Blobs Controller to handle missing files gracefully
# This controller is automatically used by Rails when placed in app/controllers/active_storage/
module ActiveStorage
  class BlobsController < ActiveStorage::BaseController
    def show
      Rails.logger.info "🔵 Custom BlobsController#show called for signed_id: #{params[:signed_id][0..20]}..."
      
      if blob
        Rails.logger.info "🔵 Blob found: key=#{blob.key[0..50]}..., filename=#{blob.filename}"
        
        # Check if the service can generate a URL
        begin
          expires_in = ActiveStorage.service_urls_expire_in
          
          # Convert filename to ActiveStorage::Filename if needed
          filename_obj = blob.filename.is_a?(String) ? ActiveStorage::Filename.new(blob.filename) : blob.filename
          
          url = blob.service.url(
            blob.key,
            expires_in: expires_in,
            disposition: params[:disposition].presence || :inline,
            filename: filename_obj,
            content_type: blob.content_type
          )
          
          Rails.logger.info "🔵 Generated URL: #{url ? url[0..100] + '...' : 'nil'}"
          
          if url.present?
            redirect_to url, allow_other_host: true
          else
            # URL is nil - blob doesn't exist in storage
            Rails.logger.warn "⚠️  Active Storage blob URL is nil for key: #{blob.key}"
            render_404
          end
        rescue => e
          Rails.logger.error "❌ Error generating Active Storage URL: #{e.message}"
          Rails.logger.error e.class.to_s
          Rails.logger.error e.backtrace.first(10).join("\n")
          render_404
        end
      else
        Rails.logger.warn "⚠️  Blob not found for signed_id: #{params[:signed_id][0..20]}..."
        render_404
      end
    end

    private

    def blob
      @blob ||= ActiveStorage::Blob.find_signed(params[:signed_id])
    rescue ActiveSupport::MessageVerifier::InvalidSignature => e
      Rails.logger.warn "⚠️  Invalid signature for blob: #{e.message}"
      nil
    rescue => e
      Rails.logger.error "❌ Error finding blob: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      nil
    end

    def render_404
      # Return a 1x1 transparent PNG instead of 500 error
      send_data(
        Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="),
        type: "image/png",
        disposition: "inline",
        status: :ok
      )
    end
  end
end

