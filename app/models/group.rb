# frozen_string_literal: true

class Group < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: "User"
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :group_recipes, dependent: :destroy
  has_many :recipes, through: :group_recipes
  has_many :group_messages, dependent: :destroy
  has_one_attached :cover_image

  # Validations
  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, length: { maximum: 1000 }
  validates :invite_code, presence: true, uniqueness: true
  validate :cover_image_size

  # Callbacks
  before_validation :generate_invite_code, on: :create
  before_validation :generate_slug, on: :create
  before_validation :regenerate_slug, on: :update, if: :name_changed?
  
  def to_param
    slug.presence || id.to_s
  end
  after_create :add_owner_as_admin

  # Scopes
  scope :public_groups, -> { where(is_private: false) }
  scope :private_groups, -> { where(is_private: true) }

  # Roles
  ROLES = %w[admin moderator member].freeze

  # Generate a unique invite code
  def generate_invite_code
    return if invite_code.present?
    
    loop do
      self.invite_code = SecureRandom.alphanumeric(8).upcase
      break unless Group.exists?(invite_code: invite_code)
    end
  end

  # Regenerate invite code (for security)
  def regenerate_invite_code!
    loop do
      new_code = SecureRandom.alphanumeric(8).upcase
      unless Group.where.not(id: id).exists?(invite_code: new_code)
        update!(invite_code: new_code)
        break
      end
    end
    invite_code
  end

  # Add owner as admin when group is created
  def add_owner_as_admin
    membership = group_memberships.build(user: owner, role: "admin", joined_at: Time.current)
    membership.save!
    # Counter cache will update automatically, but ensure it's correct
    reload
    update_column(:members_count, group_memberships.count) if members_count != group_memberships.count
  end

  # Check if user is a member
  def member?(user)
    return false unless user
    group_memberships.exists?(user: user)
  end

  # Check if user is admin
  def admin?(user)
    return false unless user
    group_memberships.exists?(user: user, role: "admin")
  end

  # Check if user is moderator or admin
  def moderator?(user)
    return false unless user
    group_memberships.exists?(user: user, role: %w[admin moderator])
  end

  # Check if user can view the group
  def viewable_by?(user)
    return false unless user
    return true if owner == user # Owner can always view
    return true unless is_private?
    member?(user)
  end

  # Check if user can add recipes
  def can_add_recipes?(user)
    member?(user)
  end

  # Check if user can manage the group
  def can_manage?(user)
    admin?(user)
  end

  # Add a member by invite code
  def self.join_by_invite_code(code, user)
    group = find_by(invite_code: code.upcase)
    return { success: false, error: "Cod de invitație invalid" } unless group
    return { success: false, error: "Ești deja membru în acest grup" } if group.member?(user)

    membership = group.group_memberships.create(user: user, role: "member", joined_at: Time.current)
    if membership.persisted?
      group.update_members_count!
      { success: true, group: group }
    else
      { success: false, error: membership.errors.full_messages.join(", ") }
    end
  end

  # Add a member
  def add_member(user, role: "member")
    return false if member?(user)
    
    membership = group_memberships.create(user: user, role: role, joined_at: Time.current)
    update_members_count! if membership.persisted?
    membership.persisted?
  end

  # Remove a member
  def remove_member(user)
    return false if user == owner # Can't remove owner
    
    membership = group_memberships.find_by(user: user)
    return false unless membership

    membership.destroy
    update_members_count!
    true
  end

  # Update member role
  def update_member_role(user, new_role)
    return false unless ROLES.include?(new_role)
    return false if user == owner && new_role != "admin" # Owner must stay admin
    
    membership = group_memberships.find_by(user: user)
    return false unless membership

    membership.update(role: new_role)
  end

  # Add a recipe to the group
  def add_recipe(recipe, added_by:, note: nil)
    return false unless can_add_recipes?(added_by)
    return false if group_recipes.exists?(recipe: recipe)

    group_recipe = group_recipes.create(recipe: recipe, added_by: added_by, note: note)
    update_recipes_count! if group_recipe.persisted?
    group_recipe.persisted?
  end

  # Remove a recipe from the group
  def remove_recipe(recipe, removed_by:)
    group_recipe = group_recipes.find_by(recipe: recipe)
    return false unless group_recipe
    return false unless moderator?(removed_by) || group_recipe.added_by == removed_by

    group_recipe.destroy
    update_recipes_count!
    true
  end

  # Update counters
  def update_members_count!
    update_column(:members_count, group_memberships.count)
  end

  def update_recipes_count!
    update_column(:recipes_count, group_recipes.count)
  end

  # Get recent messages
  def recent_messages(limit = 50)
    group_messages.includes(:user).order(created_at: :desc).limit(limit).reverse
  end

  private

  def generate_slug
    return if slug.present?
    self.slug = name.parameterize if name.present?
    # Ensure uniqueness
    if slug.present? && Group.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{slug}-#{SecureRandom.hex(4)}"
    end
  end

  def regenerate_slug
    return unless name_changed?
    self.slug = name.parameterize if name.present?
    # Ensure uniqueness
    if slug.present? && Group.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{slug}-#{SecureRandom.hex(4)}"
    end
  end

  def cover_image_size
    return unless cover_image.attached?
    
    if cover_image.blob.byte_size > 5.megabytes
      errors.add(:cover_image, "trebuie să fie mai mică de 5MB")
    end
    
    unless cover_image.blob.content_type.start_with?('image/')
      errors.add(:cover_image, "trebuie să fie o imagine")
    end
  rescue => e
    Rails.logger.error "Error validating cover image: #{e.message}"
    errors.add(:cover_image, "eroare la validarea imaginii")
  end
end
