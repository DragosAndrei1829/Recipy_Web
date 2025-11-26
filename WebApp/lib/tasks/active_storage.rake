namespace :active_storage do
  desc "Align all Active Storage blobs with the currently configured service (local/amazon/etc.)"
  task sync_service: :environment do
    target_service = Rails.application.config.active_storage.service.to_s
    mismatched_blobs = ActiveStorage::Blob.where.not(service_name: target_service)

    if mismatched_blobs.exists?
      count = mismatched_blobs.update_all(service_name: target_service)
      puts "✅ Updated #{count} blob(s) to use service '#{target_service}'."
      puts "ℹ️  Ensure the referenced files exist in the '#{target_service}' backend."
    else
      puts "👍 All blobs already use service '#{target_service}'. Nothing to do."
    end
  end
end
