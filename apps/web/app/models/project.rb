class Project < ApplicationRecord
  has_many :boards, dependent: :restrict_with_error

  validates :name, presence: true
  validates :description, presence: true
  validates :root_path, presence: true, uniqueness: true
  validates :repo_url, presence: true, uniqueness: true
  validates :stack_slug, presence: true
end
