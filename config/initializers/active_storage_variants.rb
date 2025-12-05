# Disable Active Storage variants for R2 (R2 doesn't support variant processing)
# Use CSS for image sizing instead

Rails.application.config.after_initialize do
  if Rails.env.production? && ENV['AWS_ENDPOINT'].present?
    # Override variant method on ActiveStorage::Blob to return original attachment
    # This prevents 500 errors when trying to generate variants
    ActiveStorage::Blob.class_eval do
      def variant(transformations)
        # Return self instead of creating a variant
        # CSS will handle sizing
        Rails.logger.warn "Variant requested but disabled for R2. Use CSS for sizing instead."
        self
      end
    end

    # Override representation method on ActiveStorage::Blob
    ActiveStorage::Blob.class_eval do
      def representation(transformations)
        # Return self instead of creating a representation
        Rails.logger.warn "Representation requested but disabled for R2. Use CSS for sizing instead."
        self
      end
    end

    # Also override on ActiveStorage::Attached::One and Many
    ActiveStorage::Attached::One.class_eval do
      def variant(transformations)
        Rails.logger.warn "Variant requested on attached file but disabled for R2. Use CSS for sizing instead."
        self
      end
    end

    ActiveStorage::Attached::Many.class_eval do
      def variant(transformations)
        Rails.logger.warn "Variant requested on attached files but disabled for R2. Use CSS for sizing instead."
        self
      end
    end
  end
end

