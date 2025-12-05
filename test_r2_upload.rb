#!/usr/bin/env ruby
# Test R2 Upload Script
# This script tests uploading a file to Cloudflare R2

require 'aws-sdk-s3'
require 'dotenv/load'
require 'securerandom'

puts "🔍 Testing R2 Upload..."
puts "=" * 60

# Load credentials from environment
access_key_id = ENV['AWS_ACCESS_KEY_ID']
secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
endpoint = ENV['AWS_ENDPOINT']
bucket = ENV['AWS_S3_BUCKET'] || 'recipy-production'
region = ENV['AWS_REGION'] || 'us-east-1'
region = 'us-east-1' if region == 'auto'

# Check if credentials are present
puts "\n📋 Configuration Check:"
puts "  Access Key ID: #{access_key_id ? access_key_id[0..10] + '...' : '❌ MISSING'}"
puts "  Secret Access Key: #{secret_access_key ? '✅ Present' : '❌ MISSING'}"
puts "  Endpoint: #{endpoint || '❌ MISSING'}"
puts "  Bucket: #{bucket}"
puts "  Region: #{region}"

if access_key_id.nil? || secret_access_key.nil? || endpoint.nil?
  puts "\n❌ ERROR: Missing required credentials!"
  exit 1
end

begin
  # Create S3 client for R2
  puts "\n🔌 Creating S3 client..."
  s3_client = Aws::S3::Client.new(
    access_key_id: access_key_id,
    secret_access_key: secret_access_key,
    endpoint: endpoint,
    region: region,
    force_path_style: true
  )
  
  puts "✅ S3 client created successfully"
  
  # Create a test PNG file (simple 1x1 pixel PNG)
  puts "\n📝 Creating test PNG file..."
  test_key = "test/upload_test_#{Time.now.to_i}_#{SecureRandom.hex(8)}.png"
  
  # Simple 1x1 red pixel PNG (base64 encoded)
  # This is a valid PNG file
  png_data = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, # PNG signature
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, # IHDR chunk
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, # 1x1 dimensions
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE,
    0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, # IDAT chunk
    0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, 0x00,
    0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB4,
    0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, # IEND chunk
    0xAE, 0x42, 0x60, 0x82
  ].pack('C*')
  
  # Upload test file
  puts "\n📤 Uploading test PNG file..."
  puts "  Key: #{test_key}"
  puts "  Size: #{png_data.bytesize} bytes"
  
  s3_client.put_object(
    bucket: bucket,
    key: test_key,
    body: png_data,
    content_type: 'image/png'
  )
  
  puts "✅ Successfully uploaded test file!"
  
  # Verify the file exists
  puts "\n🔍 Verifying uploaded file..."
  begin
    response = s3_client.head_object(bucket: bucket, key: test_key)
    puts "✅ File verified!"
    puts "  Content-Type: #{response.content_type}"
    puts "  Content-Length: #{response.content_length} bytes"
    puts "  Last-Modified: #{response.last_modified}"
  rescue => e
    puts "❌ Verification failed: #{e.message}"
  end
  
  # Generate presigned URL
  puts "\n🔗 Generating presigned URL..."
  presigned_url = s3_client.presigned_url(
    :get_object,
    bucket: bucket,
    key: test_key,
    expires_in: 3600
  )
  puts "✅ Presigned URL generated:"
  puts "  #{presigned_url[0..100]}..."
  
  # List objects to confirm
  puts "\n📦 Listing objects in bucket..."
  result = s3_client.list_objects_v2(bucket: bucket, prefix: "test/", max_keys: 10)
  if result.contents.any?
    puts "✅ Found #{result.contents.count} test file(s):"
    result.contents.each do |obj|
      puts "  - #{obj.key} (#{obj.size} bytes, modified: #{obj.last_modified})"
    end
  else
    puts "⚠️  No test files found"
  end
  
  puts "\n" + "=" * 60
  puts "✅ Upload test completed successfully!"
  puts "🎉 R2 upload is working correctly!"
  puts "\n💡 You can now check Cloudflare R2 dashboard - the 'last use' should be updated!"
  
rescue => e
  puts "\n" + "=" * 60
  puts "❌ FATAL ERROR: #{e.message}"
  puts "   Error class: #{e.class}"
  puts "   Backtrace:"
  e.backtrace.first(10).each do |line|
    puts "   #{line}"
  end
  exit 1
end

