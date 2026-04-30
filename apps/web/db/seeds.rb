board = Board.find_or_create_by!(project_key: "demo-factory") do |b|
  b.name = "Demo Factory Board"
end

columns = [
  [ "backlog", "Backlog" ],
  [ "in_progress", "In Progress" ],
  [ "review", "Review" ],
  [ "approved", "Approved" ],
  [ "merged", "Merged" ]
]

columns.each_with_index do |(key, title), idx|
  board.columns.find_or_create_by!(key: key) do |column|
    column.title = title
    column.position = idx
  end
end

ticket = board.tickets.find_or_create_by!(title: "Bootstrap project setup ticket") do |t|
  t.column = board.columns.find_by!(key: "backlog")
  t.description = "Initial setup task created from ingress command."
  t.priority = :high
end

label = board.labels.find_or_create_by!(name: "setup") do |l|
  l.color = "#0ea5e9"
end

TicketLabel.find_or_create_by!(ticket: ticket, label: label)
