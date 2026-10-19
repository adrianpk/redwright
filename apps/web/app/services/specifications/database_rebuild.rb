require "sqlite3"
require "fileutils"

module Specifications
  class DatabaseRebuild
    # Harness settings and retained operations are domain data copied verbatim,
    # including their private opaque references; they must not be rebuilt as indexes.
    INDEX_TABLES = %w[dumps dump_entries tickets documents document_relations schema_migrations ar_internal_metadata].freeze

    def self.prepare!(output_path:)
      original = ActiveRecord::Base.connection_db_config.configuration_hash
      original_verbose = ActiveRecord::Migration.verbose
      raise Error, "Database preparation requires SQLite." unless original[:adapter] == "sqlite3"
      output = File.expand_path(output_path)
      snapshot = "#{output}.source.sqlite3"
      raise Error, "Choose new database and snapshot paths." if File.exist?(output) || File.symlink?(output) || File.exist?(snapshot) || File.symlink?(snapshot)
      FileUtils.mkdir_p(File.dirname(output))
      backup!(original.fetch(:database), snapshot)
      begin
        File.open(output, File::WRONLY | File::CREAT | File::EXCL, 0o600) { }
        ActiveRecord::Base.establish_connection(original.merge(database: output))
        ActiveRecord::Migration.verbose = false
        ActiveRecord::Base.connection_pool.migration_context.migrate
        ActiveRecord::Base.descendants.each(&:reset_column_information)
        copy_domain_tables!(snapshot, output)
        import_dumps!(snapshot)
        import_tickets!(snapshot)
        import_documents!(snapshot)
        violations = ActiveRecord::Base.connection.select_all("PRAGMA foreign_key_check")
        raise Error, "Prepared database has invalid relationships." if violations.any?
      ensure
        ActiveRecord::Migration.verbose = original_verbose
        ActiveRecord::Base.establish_connection(original)
        ActiveRecord::Base.descendants.each(&:reset_column_information)
      end
      {database: output, source_snapshot: snapshot}
    end

    def self.backup!(source_path, snapshot)
      source = SQLite3::Database.new(source_path, readonly: true)
      target = SQLite3::Database.new(snapshot)
      File.chmod(0o600, snapshot)
      backup = SQLite3::Backup.new(target, "main", source, "main")
      backup.step(-1)
    ensure
      backup&.finish
      target&.close
      source&.close
    end

    def self.copy_domain_tables!(snapshot, output)
      source = SQLite3::Database.new(snapshot)
      target = SQLite3::Database.new(output)
      target.execute("PRAGMA foreign_keys = OFF")
      tables = source.execute("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'").flatten - INDEX_TABLES
      target.transaction do
        tables.each do |table|
          quoted = '"' + table.gsub('"', '""') + '"'
          columns = source.execute("PRAGMA table_info(#{quoted})").map { |row| row[1] }
          available = target.execute("PRAGMA table_info(#{quoted})").map { |row| row[1] }
          raise Error, "Unsupported source table: #{table}" unless (columns - available).empty?
          placeholders = (["?"] * columns.size).join(",")
          names = columns.map { |name| '"' + name.gsub('"', '""') + '"' }.join(",")
          source.execute("SELECT * FROM #{quoted}") { |row| target.execute("INSERT INTO #{quoted} (#{names}) VALUES (#{placeholders})", row) }
        end
      end
    ensure
      target&.close
      source&.close
    end

    def self.import_dumps!(snapshot)
      source = SQLite3::Database.new(snapshot)
      source.results_as_hash = true
      tables = source.execute("SELECT name FROM sqlite_master WHERE type = 'table'").map { |row| row["name"] }
      return unless tables.include?("dumps")
      Project.find_each do |project|
        rows = source.execute("SELECT * FROM dumps WHERE project_id = ?", [project.id])
        next if rows.empty?
        entries = if rows.first.key?("relative_path")
          rows.map { |row| Dumps::FileStore.new(project).read(row.fetch("relative_path")) }
        else
          notes = tables.include?("dump_entries") ? source.execute("SELECT * FROM dump_entries WHERE project_id = ?", [project.id]) : []
          tags = rows.to_h { |row| [row["id"], Tag.joins(:taggings).where(taggings: {taggable_type: "Dump", taggable_id: row["id"]}).pluck(:name)] }
          Dumps::LegacyExporter.new(project: project, dumps: rows, entries: notes, tags: tags).export!
        end
        entries.zip(rows).each do |entry, row|
          Dump.insert_all!([Dump.index_values(entry).merge(id: row.fetch("id"), project_id: project.id,
            created_at: row.fetch("created_at"), updated_at: row.fetch("updated_at"))])
        end
        Dump.reconcile!(project)
      end
    ensure
      source&.close
    end

    def self.import_documents!(snapshot)
      source = SQLite3::Database.new(snapshot)
      source.results_as_hash = true
      Project.find_each do |project|
        rows = source.execute("SELECT * FROM documents WHERE project_id = ?", [project.id])
        next if rows.empty?
        unless rows.first.key?("body")
          rows.each do |row|
            entry = FileStore.new(project).read(row.fetch("relative_path"))
            row["body"] = entry[:body]
            row["title"] = entry[:title]
            row["use_case_id"] = entry[:use_case_id]
            row["previous_relative_path"] = entry[:path]
            row["source_metadata"] = entry[:metadata]
            row["artifact_type"] = "draft" if row["artifact_type"] == "spec" && entry[:status] == "draft"
          end
        end
        edges = source.execute("SELECT * FROM document_relations").select { |edge| rows.any? { |row| row["id"] == edge["from_artifact_id"] } }
        specifications = rows.select { |row| row["artifact_type"].in?(%w[spec draft]) }
        old_layout = rows.any? { |row| row["previous_relative_path"].nil? } || specifications.any? { |row| row["use_case_id"].nil? } ||
          specifications.group_by { |row| row["use_case_id"] }.values.any? { |group| group.size > 1 }
        entries = if old_layout
          LegacyExporter.new(project: project, documents: rows, relations: edges).export!
        else
          rows.map { |row| FileStore.new(project).read(row.fetch("previous_relative_path")) }
        end
        entries.each do |entry|
          row = rows.find { |candidate| candidate["previous_relative_path"] == entry[:path] } ||
            rows.find { |candidate| candidate["id"] == entry[:metadata]["legacy_document_id"] }
          raise Error, "Exported document content differs from the source." unless entry[:body] == row.fetch("body")
          values = entry.slice(:title, :artifact_type, :status, :use_case_id, :source_hash, :source_modified_at)
          Document.insert_all!([values.merge(id: row.fetch("id"), project_id: project.id, relative_path: entry[:path], created_at: row.fetch("created_at"), updated_at: row.fetch("updated_at"))])
        end
        Document.reconcile!(project)
      end
    ensure
      source&.close
    end

    def self.import_tickets!(snapshot)
      source = SQLite3::Database.new(snapshot)
      source.results_as_hash = true
      Project.find_each do |project|
        board_ids = project.boards.pluck(:id)
        next if board_ids.empty?
        rows = source.execute("SELECT * FROM tickets WHERE board_id IN (#{board_ids.map(&:to_i).join(',')})")
        index = TicketManagement::FileIndex.new(project)
        rows.each do |row|
          if row.key?("description")
            ticket = Ticket.new(row.slice(*(Ticket.column_names + ["description"])))
            ticket.commits = JSON.parse(row["commits"]) if row["commits"].is_a?(String) && row["commits"].present?
            entry = index.write(ticket)
          else
            entry = FileStore.new(project).read(row.fetch("relative_path"))
          end
          Ticket.insert_all!([index.values_for(entry).merge(id: row.fetch("id"))])
        end
      end
    ensure
      source&.close
    end

    private_class_method :backup!, :copy_domain_tables!, :import_documents!, :import_tickets!, :import_dumps!
  end
end
