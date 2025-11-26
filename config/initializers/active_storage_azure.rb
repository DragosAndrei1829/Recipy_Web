# Active Storage Azure Blob Storage Service
# This initializer enables Azure Blob Storage support for Active Storage

require "azure/storage/blob"

# Define Azure Storage Service for Active Storage
class ActiveStorage::Service::AzureStorageService < ActiveStorage::Service
  def initialize(storage_account_name:, storage_access_key:, container:)
    @client = Azure::Storage::Blob::BlobService.create(
      storage_account_name: storage_account_name,
      storage_access_key: storage_access_key
    )
    @container = container
  end

  def upload(key, io, checksum: nil, **options)
    instrument :upload, key: key, checksum: checksum do
      @client.create_block_blob(@container, key, io.read, content_type: options[:content_type])
    end
  end

  def download(key, &block)
    instrument :download, key: key do
      blob, content = @client.get_blob(@container, key)
      if block_given?
        yield content
      else
        content
      end
    end
  end

  def download_chunk(key, range)
    instrument :download_chunk, key: key, range: range do
      blob, content = @client.get_blob(@container, key, start_range: range.begin, end_range: range.exclude_end? ? range.end - 1 : range.end)
      content
    end
  end

  def delete(key)
    instrument :delete, key: key do
      @client.delete_blob(@container, key)
    rescue Azure::Core::Http::HTTPError => e
      raise unless e.status_code == 404
    end
  end

  def delete_prefixed(prefix)
    instrument :delete_prefixed, prefix: prefix do
      @client.list_blobs(@container, prefix: prefix).each do |blob|
        @client.delete_blob(@container, blob.name)
      end
    end
  end

  def exist?(key)
    instrument :exist, key: key do |payload|
      @client.get_blob_properties(@container, key)
      true
    rescue Azure::Core::Http::HTTPError => e
      false if e.status_code == 404
      raise
    end
  end

  def url(key, expires_in:, filename:, disposition:, content_type:)
    instrument :url, key: key do |payload|
      query_string = {
        "sv" => "2019-12-12",
        "ss" => "b",
        "srt" => "co",
        "sp" => "r",
        "se" => (Time.current + expires_in).iso8601,
        "st" => Time.current.iso8601,
        "spr" => "https",
        "sig" => generate_signature(key, expires_in)
      }.to_query

      "#{@client.storage_blob_host}/#{@container}/#{key}?#{query_string}"
    end
  end

  def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
    instrument :url_for_direct_upload, key: key do |payload|
      # Azure doesn't support direct upload URLs in the same way as S3
      # Return a URL that can be used for upload
      url(key, expires_in: expires_in, filename: ActiveStorage::Filename.new(""), disposition: :inline, content_type: content_type)
    end
  end

  def headers_for_direct_upload(key, content_type:, checksum:, **)
    { "Content-Type" => content_type, "Content-MD5" => checksum, "x-ms-blob-type" => "BlockBlob" }
  end

  private

  def generate_signature(key, expires_in)
    # Simplified signature generation - in production, use proper Azure SAS token generation
    require "openssl"
    require "base64"

    canonicalized_resource = "/#{@client.storage_account_name}/#{@container}/#{key}"
    string_to_sign = [
      "r", # read permission
      (Time.current + expires_in).iso8601,
      Time.current.iso8601,
      canonicalized_resource,
      "",
      "https",
      "2019-12-12"
    ].join("\n")

    signature = Base64.strict_encode64(
      OpenSSL::HMAC.digest("sha256", Base64.strict_decode64(@client.storage_access_key), string_to_sign)
    )

    signature
  end
end

# Override the resolve method to recognize AzureStorage service
# Rails will call this method when it sees "service: AzureStorage" in storage.yml
# We use prepend to add our custom logic while preserving Rails' default behavior
module ActiveStorage
  class Service
    module AzureStorageResolver
      def resolve(service_name)
        case service_name.to_s
        when "AzureStorage"
          ActiveStorage::Service::AzureStorageService
        else
          super
        end
      end
    end

    class << self
      prepend AzureStorageResolver
    end
  end
end
