module Specifications
  class Generator
    def initialize(project:, use_case: nil, feature: nil, harness: Harness.new)
      @project, @use_case, @feature, @harness = project, use_case, feature.to_s.strip, harness
    end

    def call
      store = FileStore.new(@project)
      raise Error, "The project workspace is unavailable." unless store.root.directory?
      raise Error, "The feature description is too long." if @feature.bytesize > 4_000
      context = ContextBuilder.new(project: @project, use_case: @use_case).to_h
      context["feature"] = @feature if @feature.present?
      request_id = SecureRandom.uuid
      context["request_id"] = request_id
      output = @harness.generate(context: context, workspace: store.root.to_s)
      sources = ["- project: #{@project.id}"]
      sources += context.fetch("dumps").map { |dump| "- dump: #{dump.fetch("id")}" }
      sources += context.fetch("quiz_answers").map { |entry| entry.fetch("quiz_id") }.uniq.map { |id| "- quiz: #{id}" }
      body = output.fetch("body") + "\n\n## Provenance\n\n" + sources.join("\n") + "\n"
      document = @project.documents.new(title: output.fetch("title"), body: body, artifact_type: "spec", status: "draft", use_case: @use_case)
      document.provenance = {"source_request_id" => request_id, "source_response_id" => Digest::SHA256.hexdigest(output.to_json),
        "generation_source" => "wrapped_harness", "discovery_dump_ids" => context.fetch("dumps").map { |dump| dump.fetch("id") }}
      document.save!
      document
    end
  end
end
