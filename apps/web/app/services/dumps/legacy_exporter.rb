module Dumps
  class LegacyExporter
    def initialize(project:, dumps:, entries: [], tags: {})
      @project, @dumps, @entries, @tags = project, dumps, entries, tags
      @store = FileStore.new(project)
    end

    def export!
      @dumps.map do |row|
        path = "ops/default/dump/00000-legacy-dump-#{row.fetch('id')}/artifact.md"
        body = body_for(row)
        current = @store.read(path) if @store.root.join(path).exist?
        raise Specifications::Error, "An exported dump was edited; preserve it before exporting again." if current && current[:body] != body
        use_case = @project.use_cases.find_by(id: row["use_case_id"])
        metadata = {
          "artifact_type" => "dump", "title" => row.fetch("title"), "slug" => row.fetch("slug"),
          "status" => status_for(row), "project_id" => @project.id.to_s, "case_slug" => use_case&.slug.to_s,
          "created_at" => row.fetch("created_at"), "legacy_dump_id" => row.fetch("id"),
          "tags" => Array(@tags[row.fetch("id")])
        }
        @store.write(path: path, metadata: metadata, body: body, revision: current&.dig(:source_hash))
      end
    end

    private

    def status_for(row)
      row["status"] == "completed" ? "ready" : "draft"
    end

    def body_for(row)
      parts = [row["raw_body"].to_s.strip].reject(&:empty?)
      @entries.select { |entry| entry["dump_id"] == row["id"] }.sort_by { |entry| entry["position"] }.each do |entry|
        %w[raw_input polished_input derived_thread_hint].each do |key|
          value = entry[key].to_s.strip
          parts << value if value.present? && parts.none? { |part| part.include?(value) }
        end
      end
      summary = row["summary"].to_s.strip
      curated = row["curated_body"].to_s.strip
      unless curated.include?("No dump content was available for curation.")
        synthesis_text = curated.lines.reject { |line| line.start_with?("#") }.join.gsub(/\s+/, " ").strip
        existing_text = parts.join(" ").gsub(/\s+/, " ")
        if synthesis_text.present? && !existing_text.include?(synthesis_text)
          parts << "## Previous synthesis\n\n#{curated}"
        end
        parts << summary if summary.present? && parts.none? { |part| part.include?(summary) }
      end
      parts.join("\n\n")
    end
  end
end
