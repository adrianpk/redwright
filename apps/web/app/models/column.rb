class Column < ApplicationRecord
  belongs_to :board
  has_many :tickets, dependent: :restrict_with_error

  validates :key, presence: true, uniqueness: { scope: :board_id }
  validates :title, presence: true
  validates :position, presence: true, uniqueness: { scope: :board_id }
end
