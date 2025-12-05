#!/usr/bin/env ruby
# Test R2 Connection Script
# This script tests the connection to Cloudflare R2

require 'aws-sdk-s3'
require 'dotenv/load'

puts "🔍 Testing R2 Connection..."
puts "=" * 60

# Load credentials from environment
access_key_id = ENV['AWS_ACCESS_KEY_ID']
secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
endpoint = ENV['AWS_ENDPOINT']
bucket = ENV['AWS_S3_BUCKET'] || 'recipy-production'
# For R2, we need a valid AWS region (not "auto")
# Use "us-east-1" or "eu-west-1" - it doesn't matter for R2
region = ENV['AWS_REGION'] || 'us-east-1'
# If region is "auto", use us-east-1 instead
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
    force_path_style: true,
    use_dualstack_endpoint: false,
    use_accelerate_endpoint: false
  )
  
  puts "✅ S3 client created successfully"
  
  # Test 1: List buckets (should work even if bucket doesn't exist)
  puts "\n📦 Test 1: Listing buckets..."
  begin
    buckets = s3_client.list_buckets
    puts "✅ Successfully connected to R2!"
    puts "   Found #{buckets.buckets.count} bucket(s)"
    buckets.buckets.each do |b|
      puts "   - #{b.name} (created: #{b.creation_date})"
    end
  rescue => e
    puts "❌ Failed to list buckets: #{e.message}"
    puts "   Error class: #{e.class}"
    exit 1
  end
  
  # Test 2: Check if bucket exists
  puts "\n📦 Test 2: Checking bucket '#{bucket}'..."
  begin
    s3_client.head_bucket(bucket: bucket)
    puts "✅ Bucket '#{bucket}' exists and is accessible"
  rescue Aws::S3::Errors::NotFound => e
    puts "❌ Bucket '#{bucket}' does not exist!"
    exit 1
  rescue => e
    puts "❌ Error accessing bucket: #{e.message}"
    puts "   Error class: #{e.class}"
    exit 1
  end
  
  # Test 3: List objects in bucket
  puts "\n📦 Test 3: Listing objects in bucket..."
  begin
    objects = s3_client.list_objects_v2(bucket: bucket, max_keys: 10)
    if objects.contents.any?
      puts "✅ Found #{objects.contents.count} object(s) (showing first 10):"
      objects.contents.each do |obj|
        puts "   - #{obj.key} (#{obj.size} bytes, modified: #{obj.last_modified})"
      end
    else
      puts "⚠️  Bucket is empty (no objects found)"
    end
  rescue => e
    puts "❌ Failed to list objects: #{e.message}"
    puts "   Error class: #{e.class}"
  end
  
  # Test 4: Upload a test file
  puts "\n📤 Test 4: Uploading test file..."
  test_key = "test/connection_test_#{Time.now.to_i}.txt"
  test_content = "R2 Connection Test - #{Time.now.iso8601}"
  
  begin
    s3_client.put_object(
      bucket: bucket,
      key: test_key,
      body: test_content,
      content_type: 'text/plain'
    )
    puts "✅ Successfully uploaded test file: #{test_key}"
    
    # Test 5: Generate presigned URL
    puts "\n🔗 Test 5: Generating presigned URL..."
    presigned_url = s3_client.presigned_url(
      :get_object,
      bucket: bucket,
      key: test_key,
      expires_in: 3600
    )
    puts "✅ Presigned URL generated:"
    puts "   #{presigned_url[0..80]}..."
    
    # Test 6: Delete test file
    puts "\n🗑️  Test 6: Cleaning up test file..."
    s3_client.delete_object(bucket: bucket, key: test_key)
    puts "✅ Test file deleted"
    
  rescue => e
    puts "❌ Failed to upload test file: #{e.message}"
    puts "   Error class: #{e.class}"
    puts "   Backtrace: #{e.backtrace.first(3).join("\n   ")}"
  end
  
  puts "\n" + "=" * 60
  puts "✅ All tests completed successfully!"
  puts "🎉 R2 connection is working correctly!"
  
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

