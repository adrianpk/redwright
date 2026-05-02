class ProjectAttribute < ApplicationRecord
  belongs_to :project

  validates :key, presence: true
  validates :value, presence: true
  validates :weight, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :source, presence: true
end
