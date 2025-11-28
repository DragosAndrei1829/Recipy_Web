class VideoTimestamp < ApplicationRecord
  belongs_to :recipe
  
  validates :step_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :timestamp_seconds, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :step_number, uniqueness: { scope: :recipe_id }
  
  default_scope { order(:step_number) }
  
  # Format timestamp as MM:SS
  def formatted_time
    minutes = timestamp_seconds / 60
    seconds = timestamp_seconds % 60
    format('%02d:%02d', minutes, seconds)
  end
  
  # Get timestamp in seconds for video player
  def time_in_seconds
    timestamp_seconds
  end
end
