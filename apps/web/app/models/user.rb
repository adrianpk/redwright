require "json"

class User < ApplicationRecord
  ALLOWED_ROLES = %w[admin programmer reviewer merger qa].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  before_validation :bootstrap_admin_role, on: :create
  validate :roles_must_be_supported
  validate :single_admin_must_remain_unique
  validate :admin_role_must_be_exclusive

  def roles
    parsed = JSON.parse(roles_json.to_s)
    return [] unless parsed.is_a?(Array)

    parsed.map(&:to_s).uniq
  rescue JSON::ParserError
    []
  end

  def roles=(value)
    list = Array(value).map(&:to_s).reject(&:empty?).uniq
    self.roles_json = JSON.generate(list)
  end

  def has_role?(name)
    roles.include?(name.to_s)
  end

  def admin?
    has_role?("admin")
  end

  private

  def bootstrap_admin_role
    return unless User.where.not(id: id).empty?
    return unless roles.empty?

    self.roles = [ "admin" ]
  end

  def roles_must_be_supported
    unknown = roles - ALLOWED_ROLES
    return if unknown.empty?

    errors.add(:roles_json, "contains unsupported roles: #{unknown.join(', ')}")
  end

  def single_admin_must_remain_unique
    return unless admin?

    another_admin_exists = User.where.not(id: id).any? do |u|
      u.admin?
    end
    errors.add(:roles_json, "admin is already assigned to another user") if another_admin_exists
  end

  def admin_role_must_be_exclusive
    return unless admin?
    return if roles == [ "admin" ]

    errors.add(:roles_json, "admin cannot be combined with agent roles")
  end
end
