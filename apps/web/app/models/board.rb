class Board < ApplicationRecord
  belongs_to :project

  has_many :columns, -> { order(:position) }, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :labels, dependent: :destroy

  validates :name, presence: true
  validates :project_key, presence: true, uniqueness: true

  scope :for_project, ->(project_id) { where(project_id: project_id) }
end
