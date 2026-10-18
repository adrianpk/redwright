module Specifications
  class LegacyExporter
    def initialize(project:, documents:, relations: [])
      @project, @documents, @relations = project, documents, relations
      @store = FileStore.new(project)
    end

    def export!
      assign_features!
      paths = @documents.to_h do |row|
        directory = {"spec" => "spec", "plan_tracker" => "tracker", "internal" => "report"}.fetch(kind_for(row))
        previous = row["previous_relative_path"]
        path = previous ? previous.sub(%r{/(?:spec|tracker|report)/}, "/#{directory}/") : "ops/default/#{directory}/00000-legacy-document-#{row.fetch('id')}/artifact.md"
        [row.fetch("id"), path]
      end
      @documents.map do |row|
        path = paths.fetch(row.fetch("id"))
        current = @store.read(path) if @store.root.join(path).exist?
        raise Error, "An exported document was edited; preserve it before exporting again." if current && current[:body] != row.fetch("body")
        use_case = @features[row["id"]]
        relation_values = @relations.select { |edge| edge["from_artifact_id"] == row["id"] }.map do |edge|
          target = paths.fetch(edge.fetch("to_artifact_id")) { raise Error, "Legacy relation points outside the project." }
          {"path" => target, "type" => edge.fetch("relation_type")}
        end
        kind = kind_for(row)
        status = kind == "internal" ? "active" : {"draft" => "draft", "spec" => "approved", "plan_tracker" => "tracking"}.fetch(row.fetch("artifact_type"))
        status = row.dig("source_metadata", "status") || status if kind != "internal"
        metadata = (row["source_metadata"] || {}).merge("title" => row.fetch("title"), "artifact_type" => kind, "status" => status,
          "project_id" => row.dig("source_metadata", "project_id").presence || @project.id.to_s, "case_slug" => use_case&.slug.to_s,
          "created_at" => row.dig("source_metadata", "created_at") || row.fetch("created_at"), "legacy_document_id" => row.fetch("id"), "relations" => relation_values)
        if kind == "plan_tracker"
          source_ids = @relations.select { |edge| edge["from_artifact_id"] == row["id"] }.map { |edge| edge["to_artifact_id"] }
          source_body = @documents.select { |source| source_ids.include?(source["id"]) }.map { |source| source["body"] }.join("\n")
          source_body += row.fetch("body")
          metadata["ticket_keys"] ||= @project.boards_scope.flat_map { |board| board.tickets.ordered_for_board.select { |ticket| source_body.include?(ticket.title) }.map(&:ticket_key) }
          specification_id = source_ids.find { |id| @documents.any? { |value| value["id"] == id && kind_for(value) == "spec" } }
          if specification_id
            metadata["specification_path"] = paths.fetch(specification_id)
            specification = @store.read(metadata["specification_path"])
            metadata["specification_revision"] = specification[:source_hash]
          end
        end
        entry = @store.write(path: path, metadata: metadata, body: row.fetch("body"), revision: current&.dig(:source_hash))
        if row["previous_relative_path"] && row["previous_relative_path"] != path
          @store.root.join(row["previous_relative_path"]).delete
        end
        entry
      end
    end

    private

    def assign_features!
      @features = {}
      used = []
      @documents.select { |row| kind_for(row) == "spec" }.each do |row|
        feature = @project.use_cases.find_by(id: row["use_case_id"])
        feature = nil if feature && used.include?(feature.id)
        unless feature
          name = row.fetch("title").sub(/\s+(?:Spec|Draft)\z/, "")
          name = "#{name} #{row.fetch('id')}" if @project.use_cases.exists?(name: name)
          feature = @project.use_cases.create!(name: name, description: "Feature preserved from an existing specification.")
        end
        used << feature.id
        @features[row["id"]] = feature
      end
      @documents.each do |row|
        next if @features.key?(row["id"])
        linked = @relations.find { |edge| (edge["from_artifact_id"] == row["id"] && @features.key?(edge["to_artifact_id"])) || (edge["to_artifact_id"] == row["id"] && @features.key?(edge["from_artifact_id"])) }
        @features[row["id"]] = linked ? (@features[linked["from_artifact_id"]] || @features[linked["to_artifact_id"]]) : @project.use_cases.find_by(id: row["use_case_id"])
      end
    end

    def kind_for(row)
      return "plan_tracker" if row["artifact_type"] == "plan_tracker"
      return "internal" if row["artifact_type"] == "internal"
      return "internal" if row["artifact_type"] == "draft" && ["Project Setup Summary", "Guided Alignment Summary"].include?(row["title"])
      if row["artifact_type"] == "draft"
        referenced = @relations.any? { |edge| edge["to_artifact_id"] == row["id"] && edge["relation_type"] == "derives_from" }
        return "internal" if referenced || @documents.any? { |other| other["source_draft_id"] == row["id"] }
      end
      "spec"
    end
  end
end
