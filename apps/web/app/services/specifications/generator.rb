module Specifications
  class Generator
    def initialize(project:, use_case: nil, feature: nil, harness: Harness.new, authoring: Harnesses::Authoring)
      @project, @use_case, @feature, @harness = project, use_case, feature.to_s.strip, harness
      @authoring = authoring
    end

    def call
      raise Error, "Choose the feature's use case before generating its specification." unless @use_case
      Document.reconcile!(@project)
      workflow = Features::Workflow.new(@use_case)
      workflow.ensure_mutable!
      document = @use_case.reload.specification
      revision = document&.source_hash
      store = FileStore.new(@project)
      raise Error, "The project workspace is unavailable." unless store.root.directory?
      raise Error, "The feature description is too long." if @feature.bytesize > 4_000
      context = ContextBuilder.new(project: @project, use_case: @use_case).to_h
      context["feature"] = @feature if @feature.present?
      context["current_specification"] = {"title" => document.title, "body" => document.body} if document
      request_id = SecureRandom.uuid
      context["request_id"] = request_id
      authoring = @authoring.new(project: @project, purpose: "specification", schema: Harness::OUTPUT_SCHEMA,
        harness: @harness, workspace_revision: {"use_case_ref" => @use_case.id.to_s, "revision" => revision})
      authoring.run do |harness|
        output = harness.generate(context: context, workspace: store.root.to_s)
        sources = ["- project: #{@project.id}"]
        sources += context.fetch("dumps").map { |dump| "- dump: #{dump.fetch("relative_path")}" }
        sources += context.fetch("quiz_answers").map { |entry| entry.fetch("quiz_id") }.uniq.map { |id| "- quiz: #{id}" }
        body = output.fetch("body") + "\n\n## Provenance\n\n" + sources.join("\n") + "\n"
        document ||= @project.documents.new(artifact_type: "spec", use_case: @use_case)
        document.assign_attributes(title: output.fetch("title"), body: body, status: "draft")
        document.revision = revision
        document.provenance = {"source_request_id" => request_id, "source_response_id" => Digest::SHA256.hexdigest(output.to_json),
          "generation_source" => "wrapped_harness", "discovery_dump_paths" => context.fetch("dumps").map { |dump| dump.fetch("relative_path") }}
        workflow.with_lock do
          workflow.ensure_mutable!
          harness.check_deadline! if harness.respond_to?(:check_deadline!)
          document.save!
          workflow.invalidate_tracker!
        end
        document
      end
    end
  end
end
