# Override Active Storage Blobs Controller to handle missing files gracefully
module ActiveStorage
  class BlobsController < ActiveStorage::BaseController
    def show
      if blob
        # Check if the service can generate a URL
        begin
          expires_in = ActiveStorage.service_urls_expire_in
          url = blob.service.url(
            blob.key,
            expires_in: expires_in,
            disposition: params[:disposition].presence || :inline,
            filename: blob.filename.to_s,
            content_type: blob.content_type
          )
          
          if url.present?
            redirect_to url, allow_other_host: true
          else
            # URL is nil - blob doesn't exist in storage
            Rails.logger.warn "Active Storage blob URL is nil for key: #{blob.key}"
            render_404
          end
        rescue => e
          Rails.logger.error "Error generating Active Storage URL: #{e.message}"
          Rails.logger.error e.backtrace.first(5).join("\n")
          render_404
        end
      else
        render_404
      end
    end

    private

    def blob
      @blob ||= ActiveStorage::Blob.find_signed(params[:signed_id])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
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

