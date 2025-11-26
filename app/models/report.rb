class Report < ApplicationRecord
  belongs_to :reporter, class_name: 'User'
  belongs_to :reportable, polymorphic: true, counter_cache: :reports_count
  belongs_to :reviewed_by, class_name: 'User', optional: true

  # Status enum
  enum :status, {
    pending: 0,
    under_review: 1,
    resolved_valid: 2,    # Report was valid, action taken
    resolved_invalid: 3,  # Report was invalid/spam
    dismissed: 4
  }, default: :pending

  # Reason categories
  REASONS = {
    inappropriate_content: 'Conținut inadecvat',
    spam: 'Spam sau publicitate',
    harassment: 'Hărțuire sau bullying',
    hate_speech: 'Discurs de ură',
    violence: 'Violență sau conținut periculos',
    copyright: 'Încălcare drepturi de autor',
    misinformation: 'Informații false',
    other: 'Altele'
  }.freeze

  validates :reason, presence: true, inclusion: { in: REASONS.keys.map(&:to_s) }
  validates :reporter_id, uniqueness: { 
    scope: [:reportable_type, :reportable_id], 
    message: 'Ai raportat deja acest conținut' 
  }

  # Scopes
  scope :pending_review, -> { where(status: [:pending, :under_review]) }
  scope :resolved, -> { where(status: [:resolved_valid, :resolved_invalid, :dismissed]) }
  scope :for_recipes, -> { where(reportable_type: 'Recipe') }
  scope :for_users, -> { where(reportable_type: 'User') }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_create :check_quarantine_threshold
  after_update :notify_if_resolved, if: :saved_change_to_status?

  # Thresholds
  QUARANTINE_THRESHOLD = 5  # Reports needed to quarantine a recipe
  USER_WARNING_THRESHOLD = 10  # Reports needed to flag a user for review

  def reason_label
    REASONS[reason.to_sym] || reason
  end

  def mark_as_reviewed!(admin, new_status, notes = nil)
    update!(
      status: new_status,
      reviewed_by: admin,
      reviewed_at: Time.current,
      admin_notes: notes
    )
  end

  private

  def check_quarantine_threshold
    return unless reportable_type == 'Recipe'
    
    recipe = reportable
    total_reports = recipe.reports.pending_review.count
    
    if total_reports >= QUARANTINE_THRESHOLD && !recipe.quarantined?
      recipe.quarantine!("Auto-carantină: #{total_reports} rapoarte primite")
    end

    # Also check user warning threshold
    user = recipe.user
    user_total_reports = Report.where(reportable: user.recipes).pending_review.count
    if user_total_reports >= USER_WARNING_THRESHOLD
      # Just increment the counter, admin will review
      user.increment!(:reports_count) unless user.reports_count >= user_total_reports
    end
  end

  def notify_if_resolved
    # Could send notification to reporter about resolution
    # For now, just logging
    Rails.logger.info "Report ##{id} resolved with status: #{status}"
  end
end
