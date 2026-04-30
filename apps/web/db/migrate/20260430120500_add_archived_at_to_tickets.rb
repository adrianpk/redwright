class AddArchivedAtToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :archived_at, :datetime
    add_index :tickets, :archived_at
  end
end

