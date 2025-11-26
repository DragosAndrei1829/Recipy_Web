# AWS S3 Configuration
# This initializer configures AWS SDK to handle SSL certificate issues on macOS

if Rails.env.development?
  require 'aws-sdk-s3'
  require 'openssl'
  
  # Fix SSL certificate verification issues on macOS
  # This is a workaround for the "certificate verify failed" error
  # The issue is often caused by outdated or missing CA certificates
  
  begin
    # Try to use the system's CA bundle
    # On macOS, this is typically at /usr/local/etc/openssl/cert.pem or /etc/ssl/cert.pem
    ca_bundle_paths = [
      '/opt/homebrew/etc/openssl@3/cert.pem',
      '/opt/homebrew/etc/ca-certificates/cert.pem',
      '/usr/local/etc/openssl/cert.pem',
      '/usr/local/etc/ca-certificates/cert.pem',
      '/etc/ssl/cert.pem'
    ]
    
    ca_bundle = ca_bundle_paths.find { |path| File.exist?(path) }
    
    if ca_bundle
      # Configure AWS SDK to use the CA bundle
      Aws.config.update(
        ssl_verify_peer: true,
        ssl_ca_bundle: ca_bundle
      )
    else
      # If no CA bundle found, try to update certificates or use a workaround
      # For development only: disable SSL verification (NOT RECOMMENDED FOR PRODUCTION)
      Rails.logger.warn "AWS S3: No CA bundle found. Using workaround for SSL verification (development only)."
      
      # Configure AWS SDK to skip SSL verification (DEVELOPMENT ONLY)
      Aws.config.update(
        ssl_verify_peer: false
      )
    end
  rescue => e
    Rails.logger.error "AWS S3 SSL configuration error: #{e.message}"
    # Fallback: disable SSL verification for development
    Aws.config.update(
      ssl_verify_peer: false
    )
  end
end

