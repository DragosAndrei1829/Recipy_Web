class OauthIdentity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  PROVIDERS = %w[google_oauth2 apple].freeze

  validates :provider, inclusion: { in: PROVIDERS }
end
