class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  validates :username, presence: true, uniqueness: true, unless: :oauth_user?
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :timeoutable, :lockable, :omniauthable, omniauth_providers: [ :google_oauth2, :apple ]
  # :lockable - locks account after X failed attempts (configured in devise.rb)

  # Prevent Devise from trying to assign :login attribute
  def login=(value)
    # Do nothing - login is not a real attribute
  end

  def login
    # Return nil or email/username for display purposes
    email || username
  end

  # Email confirmation with 6-digit code
  # Note: We're not using Devise's :confirmable, we're implementing our own

  # Custom validation for email - allow admin user without email
  validates :email, presence: true, unless: -> { username == "admin" }
  validates :email, uniqueness: true, allow_blank: true
  validate :password_complexity, if: :password_required?
  has_one_attached :avatar
  attr_accessor :phone
  
  # Slug generation
  before_validation :generate_slug, on: :create
  before_validation :regenerate_slug, on: :update, if: :username_changed?
  
  def to_param
    slug.presence || id.to_s
  end
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_recipes, through: :favorites, source: :recipe
  has_many :user_shortcuts, dependent: :destroy

  # Follow relationships
  has_many :follows, foreign_key: :follower_id, dependent: :destroy
  has_many :following, through: :follows, source: :user
  has_many :followers_relations, class_name: "Follow", foreign_key: :user_id, dependent: :destroy
  has_many :followers, through: :followers_relations, source: :follower

  # Notifications
  has_many :notifications, dependent: :destroy
  has_many :unread_notifications, -> { where(read: false) }, class_name: "Notification"

  # Conversations and Messages
  has_many :sent_conversations, class_name: "Conversation", foreign_key: "sender_id", dependent: :destroy
  has_many :received_conversations, class_name: "Conversation", foreign_key: "recipient_id", dependent: :destroy
  has_many :messages, dependent: :destroy

  # Shared Recipes
  has_many :sent_shared_recipes, class_name: "SharedRecipe", foreign_key: "sender_id", dependent: :destroy
  has_many :received_shared_recipes, class_name: "SharedRecipe", foreign_key: "recipient_id", dependent: :destroy

  # Reports (as reporter)
  has_many :submitted_reports, class_name: "Report", foreign_key: "reporter_id", dependent: :destroy
  # Reports (as target)
  has_many :reports, as: :reportable, dependent: :destroy

  # OAuth identities
  has_many :oauth_identities, dependent: :destroy

  # Groups
  has_many :owned_groups, class_name: "Group", foreign_key: "owner_id", dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :group_messages, dependent: :destroy
  
  # Collections
  has_many :collections, dependent: :destroy

  # Meal Planning
  has_many :meal_plans, dependent: :destroy
  
  # Shopping Lists
  has_many :shopping_lists, dependent: :destroy

  # Challenges
  has_many :created_challenges, class_name: "Challenge", foreign_key: "user_id", dependent: :destroy
  has_many :challenge_participants, dependent: :destroy
  has_many :challenges, through: :challenge_participants

  # Theme preference
  belongs_to :theme, optional: true

  # Moderation scopes
  scope :active, -> { where(blocked: false) }
  scope :blocked, -> { where(blocked: true) }
  scope :with_reports, -> { where('reports_count > 0') }

  def conversations
    Conversation.for_user(self).includes(:sender, :recipient, messages: :user).order(updated_at: :desc)
  end

  def unread_messages_count
    conversations.sum { |c| c.unread_messages_count_for(self) }
  end

  def oauth_user?
    provider.present?
  end

  def admin?
    admin == true || username == "admin" || email == "andrei247dml@gmail.com"
  end

  # Block user
  def block!(reason = nil)
    update!(
      blocked: true,
      blocked_at: Time.current,
      blocked_reason: reason,
      suspension_count: suspension_count + 1
    )
  end

  # Unblock user
  def unblock!
    update!(
      blocked: false,
      blocked_at: nil,
      blocked_reason: nil
    )
  end

  # Check if user can perform actions
  def can_post?
    !blocked?
  end

  # Override active_for_authentication to block suspended users
  def active_for_authentication?
    super && !blocked?
  end

  # Message shown to blocked users
  def inactive_message
    blocked? ? :blocked : super
  end

  def self.from_omniauth(auth)
    # First try to find by OAuth identity
    oauth_identity = OauthIdentity.find_by(provider: auth.provider, uid: auth.uid)
    return oauth_identity.user if oauth_identity

    # Then try to find by provider/uid on user (legacy)
    user = find_by(provider: auth.provider, uid: auth.uid)
    
    # Then try to find by email
    user ||= find_by(email: auth.info.email)
    
    if user
      # Update OAuth info if user exists
      user.update(provider: auth.provider, uid: auth.uid) if user.provider.blank?
      # Create OAuth identity link
      user.oauth_identities.find_or_create_by(provider: auth.provider, uid: auth.uid)
    else
      # Create new user
      user = new(
        email: auth.info.email,
        provider: auth.provider,
        uid: auth.uid,
        username: generate_unique_username(auth.info.email, auth.info.name),
        first_name: auth.info.first_name || auth.info.name&.split&.first,
        last_name: auth.info.last_name || auth.info.name&.split&.drop(1)&.join(" "),
        password: Devise.friendly_token[0, 20],
        terms_accepted: true,
        privacy_policy_accepted: true
      )
      
      # Skip email confirmation for OAuth users
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
      user.confirmed_at = Time.current
      
      if user.save
        # Create OAuth identity
        user.oauth_identities.create(provider: auth.provider, uid: auth.uid)
        
        # Download avatar if available
        if auth.info.image.present?
          begin
            require "open-uri"
            downloaded_image = URI.open(auth.info.image)
            user.avatar.attach(io: downloaded_image, filename: "avatar.jpg", content_type: "image/jpeg")
          rescue => e
            Rails.logger.error "Failed to download avatar: #{e.message}"
          end
        end
      end
    end
    
    user
  end

  def self.generate_unique_username(email, name)
    base = name&.parameterize&.underscore || email&.split("@")&.first || "user"
    base = base.gsub(/[^a-z0-9_]/, "")[0, 15]
    username = base
    
    counter = 1
    while exists?(username: username)
      username = "#{base[0, 12]}#{counter}"
      counter += 1
    end
    
    username
  end

  # Allow authentication with username or email via :login parameter
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup

    Rails.logger.info "User.find_for_database_authentication called with: #{conditions.inspect}"

    # Handle :login parameter (can be email or username)
    if login = conditions.delete(:login)
      user = where(conditions.to_h).where([ "username = :value OR email = :value", { value: login } ]).first
      Rails.logger.info "Found user by login '#{login}': #{user ? user.email : 'NOT FOUND'}"
      return user
    end

    # Fallback: try email or username if login is not present
    if email = conditions.delete(:email)
      user = where(conditions.to_h).where([ "email = :value", { value: email } ]).first
      Rails.logger.info "Found user by email '#{email}': #{user ? user.email : 'NOT FOUND'}"
      return user
    end

    if username = conditions.delete(:username)
      user = where(conditions.to_h).where([ "username = :value", { value: username } ]).first
      Rails.logger.info "Found user by username '#{username}': #{user ? user.email : 'NOT FOUND'}"
      return user
    end

    # Fallback to standard Devise behavior
    user = where(conditions.to_h).first
    Rails.logger.info "Found user by conditions: #{user ? user.email : 'NOT FOUND'}"
    user
  end

  # Generate a 6-digit confirmation code
  def generate_confirmation_code!
    code = rand(100000..999999).to_s
    update_columns(
      confirmation_code: code,
      confirmation_code_sent_at: Time.current
    )
    code
  end

  # Check if confirmation code is valid
  def confirmation_code_valid?(code)
    return false if confirmation_code.blank? || code.blank?
    return false if confirmation_code_sent_at.nil?
    return false if Time.current > confirmation_code_sent_at + 15.minutes

    confirmation_code == code.to_s
  end

  # Confirm email with code
  def confirm_email_with_code!(code)
    if confirmation_code_valid?(code)
      update_columns(
        confirmation_code: nil,
        confirmation_code_sent_at: nil,
        confirmed_at: Time.current
      )
      true
    else
      false
    end
  end

  # Check if email is confirmed
  # Bypass for existing users (created before confirmation system) and admins
  def email_confirmed?
    return true if admin? # Admins don't need confirmation
    return true if confirmed_at.present? # Already confirmed
    return true if confirmation_code.blank? && confirmation_code_sent_at.nil? && created_at < 1.day.ago # Existing users before confirmation system
    false
  end

  # Override active_for_authentication? to allow existing users and admins
  # We allow ALL users to authenticate - confirmation is optional for existing users
  def active_for_authentication?
    # Always allow authentication - we don't block based on confirmation status
    # Confirmation is only required for NEW users (those created after confirmation system)
    # Existing users (created before confirmation system) can always authenticate
    super
  end

  # Set confirmed_at for existing users on save if they don't have confirmation code
  before_save :auto_confirm_existing_users

  private

  def generate_slug
    return if slug.present?
    self.slug = username.parameterize if username.present?
    # Ensure uniqueness
    if slug.present? && User.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{slug}-#{SecureRandom.hex(4)}"
    end
  end

  def regenerate_slug
    return unless username_changed?
    self.slug = username.parameterize if username.present?
    # Ensure uniqueness
    if slug.present? && User.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{slug}-#{SecureRandom.hex(4)}"
    end
  end

  def auto_confirm_existing_users
    # Auto-confirm existing users (created before confirmation system) and admins
    if (confirmation_code.blank? && confirmation_code_sent_at.nil? && confirmed_at.nil?) &&
       (admin? || (created_at.present? && created_at < 1.day.ago))
      self.confirmed_at ||= Time.current
    end
  end

  def password_complexity
    return if password.blank?

    complexity_regex = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[[:^alnum:]]).{8,}\z/
    return if password.match?(complexity_regex)

    errors.add(:password, I18n.t("activerecord.errors.models.user.attributes.password.complexity"))
  end
end
