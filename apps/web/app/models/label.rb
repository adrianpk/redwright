class Label < ApplicationRecord
  belongs_to :board
  has_many :ticket_labels, dependent: :destroy
  has_many :tickets, through: :ticket_labels

  validates :name, presence: true, uniqueness: { scope: :board_id }
  validates :color, presence: true
end
