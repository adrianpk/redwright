module Specifications
  class LegacyExporter
    def initialize(project:, documents:, relations: [])
      @project, @documents, @relations = project, documents, relations
      @store = FileStore.new(project)
    end

    def export!
      paths = @documents.to_h do |row|
        directory = {"spec" => "spec", "plan_tracker" => "tracker", "internal" => "report"}.fetch(kind_for(row))
        [row.fetch("id"), "ops/default/#{directory}/00000-legacy-document-#{row.fetch('id')}/artifact.md"]
      end
      @documents.map do |row|
        path = paths.fetch(row.fetch("id"))
        if @store.root.join(path).exist?
          current = @store.read(path)
          raise Error, "An exported document was edited; preserve it before exporting again." unless current[:body].strip == row.fetch("body").strip
          next current
        end
        use_case = @project.use_cases.find_by(id: row["use_case_id"]) if row["use_case_id"]
        relation_values = @relations.select { |edge| edge["from_artifact_id"] == row["id"] }.map do |edge|
          target = paths.fetch(edge.fetch("to_artifact_id")) { raise Error, "Legacy relation points outside the project." }
          {"path" => target, "type" => edge.fetch("relation_type")}
        end
        kind = kind_for(row)
        status = kind == "internal" ? "active" : {"draft" => "draft", "spec" => "approved", "plan_tracker" => "tracking"}.fetch(row.fetch("artifact_type"))
        metadata = {"title" => row.fetch("title"), "artifact_type" => kind, "status" => status,
          "project_id" => @project.id.to_s, "case_slug" => use_case&.slug.to_s,
          "created_at" => row.fetch("created_at"), "legacy_document_id" => row.fetch("id"), "relations" => relation_values}
        if kind == "plan_tracker"
          source_ids = @relations.select { |edge| edge["from_artifact_id"] == row["id"] }.map { |edge| edge["to_artifact_id"] }
          source_body = @documents.select { |source| source_ids.include?(source["id"]) }.map { |source| source["body"] }.join("\n")
          source_body += row.fetch("body")
          metadata["ticket_keys"] = @project.boards_scope.flat_map { |board| board.tickets.ordered_for_board.select { |ticket| source_body.include?(ticket.title) }.map(&:ticket_key) }
        end
        @store.write(path: path, metadata: metadata, body: row.fetch("body"))
      end
    end

    private

    def kind_for(row)
      return "plan_tracker" if row["artifact_type"] == "plan_tracker"
      return "internal" if row["artifact_type"] == "draft" && ["Project Setup Summary", "Guided Alignment Summary"].include?(row["title"])
      "spec"
    end
  end
end
