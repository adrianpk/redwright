class RenameHumanKeyToTicketKeyOnTickets < ActiveRecord::Migration[8.1]
  def up
    return unless column_exists?(:tickets, :human_key)
    return if column_exists?(:tickets, :ticket_key)

    rename_column :tickets, :human_key, :ticket_key
    rename_index :tickets, "index_tickets_on_human_key", "index_tickets_on_ticket_key" if index_name_exists?(:tickets, "index_tickets_on_human_key")
  end

  def down
    return unless column_exists?(:tickets, :ticket_key)
    return if column_exists?(:tickets, :human_key)

    rename_column :tickets, :ticket_key, :human_key
    rename_index :tickets, "index_tickets_on_ticket_key", "index_tickets_on_human_key" if index_name_exists?(:tickets, "index_tickets_on_ticket_key")
  end
end
