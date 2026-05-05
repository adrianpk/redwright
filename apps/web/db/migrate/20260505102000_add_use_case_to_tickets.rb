class AddUseCaseToTickets < ActiveRecord::Migration[8.1]
  def change
    add_reference :tickets, :use_case, foreign_key: true
    add_index :tickets, [ :board_id, :use_case_id ]
  end
end
