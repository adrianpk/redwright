class Board < ApplicationRecord
  has_many :columns, -> { order(:position) }, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :labels, dependent: :destroy

  validates :name, presence: true
  validates :project_key, presence: true, uniqueness: true
end
