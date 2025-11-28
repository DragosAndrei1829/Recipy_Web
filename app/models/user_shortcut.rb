class UserShortcut < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, length: { maximum: 50 }
  validates :url, presence: true
  validates :color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color" }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :visible, -> { ordered }

  before_validation :set_default_position, on: :create
  before_validation :normalize_color

  private

  def set_default_position
    return if position.present?
    max_position = user.user_shortcuts.maximum(:position) || -1
    self.position = max_position + 1
  end

  def normalize_color
    return unless color.present?
    # Ensure color starts with #
    self.color = "##{color}" unless color.start_with?('#')
    # Convert 3-digit hex to 6-digit
    if color.length == 4 && color.start_with?('#')
      self.color = "##{color[1] * 2}#{color[2] * 2}#{color[3] * 2}"
    end
  end
end
