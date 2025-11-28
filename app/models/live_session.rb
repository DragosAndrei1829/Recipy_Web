class LiveSession < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, optional: true
  
  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :status, inclusion: { in: %w[scheduled live ended cancelled] }
  validates :scheduled_at, presence: true, if: -> { status == 'scheduled' }
  
  scope :upcoming, -> { where(status: 'scheduled').where('scheduled_at > ?', Time.current).order(:scheduled_at) }
  scope :live_now, -> { where(status: 'live') }
  scope :past, -> { where(status: %w[ended cancelled]).order(scheduled_at: :desc) }
  
  # Generate unique stream key
  before_create :generate_stream_key
  
  def live?
    status == 'live'
  end
  
  def upcoming?
    status == 'scheduled' && scheduled_at > Time.current
  end
  
  def start!
    update!(
      status: 'live',
      started_at: Time.current,
      stream_key: generate_stream_key
    )
  end
  
  def end!
    update!(
      status: 'ended',
      ended_at: Time.current
    )
  end
  
  def increment_viewer_count!
    increment!(:viewer_count)
  end
  
  def decrement_viewer_count!
    decrement!(:viewer_count) if viewer_count > 0
  end
  
  private
  
  def generate_stream_key
    self.stream_key ||= SecureRandom.hex(32)
  end
end
