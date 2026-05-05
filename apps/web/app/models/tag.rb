class Tag < ApplicationRecord
  has_many :taggings, dependent: :restrict_with_error

  before_validation :normalize_name

  validates :name, presence: true, uniqueness: true

  def self.normalize_name(value)
    value.to_s.strip.downcase.parameterize
  end

  def self.find_or_create_normalized!(value)
    find_or_create_by!(name: normalize_name(value))
  end

  private

  def normalize_name
    self.name = self.class.normalize_name(name)
  end
end
