class AddHumanKeyToTickets < ActiveRecord::Migration[8.1]
  def up
    add_column :tickets, :human_key, :string
    add_index :tickets, :human_key, unique: true

    say_with_time "Backfilling ticket human keys" do
      select_all("SELECT id FROM tickets ORDER BY created_at ASC, id ASC").each_with_index do |row, index|
        key = "RW-#{index + 1}"
        execute <<~SQL.squish
          UPDATE tickets
          SET human_key = #{quote(key)}
          WHERE id = #{Integer(row.fetch("id"))}
        SQL
      end
    end
  end

  def down
    remove_index :tickets, :human_key
    remove_column :tickets, :human_key
  end
end
