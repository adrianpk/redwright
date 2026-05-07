class DropTicketDocumentLinks < ActiveRecord::Migration[8.0]
  def change
    drop_table :ticket_document_links do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.string :role, null: false, default: "reference"
      t.timestamps

      t.index [ :ticket_id, :document_id ],
        unique: true,
        name: "idx_ticket_document_links_unique_ticket_artifact"
    end
  end
end
