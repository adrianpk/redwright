require "test_helper"
require "tmpdir"

module AgentTicketExecution
  class ContextComposerTest < ActiveSupport::TestCase
    test "composes ticket execution context sections for the request engine" do
      with_agent_ticket_execution_workspace do |fixture|
        write_runtime_setup(fixture.project_path)
        write_project_protocols(fixture.project, fixture.project_path)
        draft = create_document(project: fixture.project, title: "Implementation Draft", body: "Draft body")
        create_document(project: fixture.project, artifact_type: "spec", title: "Implementation Spec", body: "Spec body", source_draft: draft, editable: false)
        create_document(project: fixture.project, artifact_type: "plan_tracker", title: "Implementation Plan", body: "Plan body", editable: false)
        store = write_previous_interactions(fixture.ticket)

        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(
          ticket: fixture.ticket,
          branch_name: "feature/todo-done"
        )
        context = ContextComposer.new(previous_interaction_store: store).compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done"),
          workspace: workspace
        )

        sections = context.context_sections.index_by(&:name)
        assert_equal(
          %w[ticket project repository_tree relevant_files tests operational_setup protocol_files protocol_model documents previous_interactions],
          sections.keys
        )
        assert_equal "ticket_record", sections.fetch("ticket").authority
        assert_equal "workspace_filesystem", sections.fetch("relevant_files").authority
        assert_equal "project_protocol_model", sections.fetch("protocol_model").authority
        assert_equal "project_protocol_model", sections.fetch("protocol_files").authority
        assert_equal "project_documents", sections.fetch("documents").authority
        assert_equal "historical_agent_llm_interaction", sections.fetch("previous_interactions").authority
        assert_includes sections.fetch("ticket").content.fetch("description"), "done <task-number>"
        assert_includes sections.fetch("repository_tree").content.fetch("entries").map { |entry| entry.fetch("path") }, "main.go"
        refute_includes sections.fetch("repository_tree").content.fetch("entries").map { |entry| entry.fetch("path") }, "AGENTS.md"
        refute_includes sections.fetch("repository_tree").content.fetch("entries").map { |entry| entry.fetch("path") }, ".agents/CONVENTIONS.md"
        assert_includes sections.fetch("relevant_files").content.map { |file| file.fetch("path") }, "main.go"
        refute_includes sections.fetch("relevant_files").content.map { |file| file.fetch("path") }, "AGENTS.md"
        refute_includes sections.fetch("relevant_files").content.map { |file| file.fetch("path") }, ".agents/CONVENTIONS.md"
        assert_includes sections.fetch("tests").content.map { |file| file.fetch("path") }, "main_test.go"
        assert_equal "available", sections.fetch("operational_setup").content.fetch("status")
        assert_includes sections.fetch("protocol_files").content.map { |file| file.fetch("path") }, "AGENTS.md"
        assert_includes sections.fetch("protocol_files").content.map { |file| file.fetch("path") }, ".agents/CONVENTIONS.md"
        assert_includes sections.fetch("protocol_files").content.first.fetch("content"), "Use Conventional Commits"
        assert_equal "docs", sections.fetch("documents").metadata.fetch("context_layer")
        assert_includes sections.fetch("documents").content.fetch("documents").map { |document| document.fetch("title") }, "Implementation Spec"
        assert_includes sections.fetch("documents").content.fetch("documents").map { |document| document.fetch("title") }, "Implementation Plan"
        assert_includes sections.fetch("documents").content.fetch("omitted_documents").map { |document| document.fetch("title") }, "Implementation Draft"
        assert_equal false, sections.fetch("previous_interactions").content.fetch("human_chat_included")
        assert_equal 1, sections.fetch("previous_interactions").content.fetch("records").length

        assert_equal sections.keys, context.diagnostics.fetch("section_names")
        assert_operator context.diagnostics.fetch("context_bytes"), :>, 0
        assert_equal fixture.ticket.id, context.trace_metadata.fetch(:ticket_id)
        assert_equal fixture.project_path, context.trace_metadata.fetch(:project_root)
        assert_equal "test", context.trace_metadata.fetch(:source_channel)
        assert_equal "agent-test", context.trace_metadata.fetch(:actor_identifier)
        assert_equal context.context_sections, context.llm_request_inputs.fetch(:context_sections)
      end
    end

    test "selects protocol documents from modeled state by policy attributes" do
      with_agent_ticket_execution_workspace do |fixture|
        protocol = fixture.project.create_protocol!(status: "draft")
        protocol.documents.create!(
          key: "agents_root",
          path: "AGENTS.md",
          title: "AGENTS",
          layer: "behavioral",
          position: 0,
          body: "Root instructions.",
          provenance: {"source" => "test"}
        )
        protocol.documents.create!(
          key: "runtime_stack",
          path: ".agents/RUNTIME.md",
          title: "Runtime",
          layer: "stack",
          position: 1,
          body: "Runtime stack instructions.",
          provenance: {"source" => "test"}
        )

        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        implementation_context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge("context_policy" => "implementation_default"),
          workspace: workspace
        )
        planning_context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge("context_policy" => "planning_default"),
          workspace: workspace
        )

        implementation_protocols = implementation_context.context_sections.index_by(&:name).fetch("protocol_files")
        planning_protocols = planning_context.context_sections.index_by(&:name).fetch("protocol_files")
        assert_equal %w[AGENTS.md .agents/RUNTIME.md], implementation_protocols.content.map { |document| document.fetch("path") }
        assert_equal ["AGENTS.md"], planning_protocols.content.map { |document| document.fetch("path") }
        assert_equal "protocols", implementation_protocols.metadata.fetch("context_layer")
        assert_equal "test", implementation_protocols.metadata.fetch("selected_protocol_documents").last.fetch("provenance").fetch("source")
      end
    end

    test "selects document context separately from protocols" do
      with_agent_ticket_execution_workspace do |fixture|
        draft = create_document(project: fixture.project, title: "Feature Draft", body: "Draft body")
        create_document(project: fixture.project, artifact_type: "spec", title: "Feature Spec", body: "Spec body", source_draft: draft, editable: false)
        create_document(project: fixture.project, artifact_type: "plan_tracker", title: "Feature Plan", body: "Plan body", editable: false)
        write_project_protocols(fixture.project, fixture.project_path)

        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge("context_policy" => "implementation_default"),
          workspace: workspace
        )

        sections = context.context_sections.index_by(&:name)
        documents = sections.fetch("documents")
        protocol_files = sections.fetch("protocol_files")
        selected_titles = documents.content.fetch("documents").map { |document| document.fetch("title") }
        omitted_titles = documents.content.fetch("omitted_documents").map { |document| document.fetch("title") }

        assert_includes selected_titles, "Feature Spec"
        assert_includes selected_titles, "Feature Plan"
        assert_includes omitted_titles, "Feature Draft"
        refute_includes selected_titles, "AGENTS"
        assert_includes protocol_files.content.map { |document| document.fetch("title") }, "AGENTS"
        assert_equal "document_context_inventory", documents.metadata.fetch("selection_source")
        assert_equal "matched_artifact_type:spec", documents.metadata.fetch("selected_documents").find { |document| document.fetch("title") == "Feature Spec" }.fetch("selection_reason")
        assert_equal "unselected_artifact_type:draft", documents.metadata.fetch("omitted_documents").find { |document| document.fetch("title") == "Feature Draft" }.fetch("omission_reason")
      end
    end

    private

    def request_payload(branch_name:)
      {
        "mode" => "targeted",
        "branch_name" => branch_name,
        "session_id" => "ticket-run-1",
        "agent_id" => "agent-coder",
        "source_channel" => "test",
        "actor_identifier" => "agent-test"
      }
    end

    def write_runtime_setup(project_path)
      FileUtils.mkdir_p(File.join(project_path, ".rw", "agent"))
      File.write(File.join(project_path, ".rw", "agent", "Dockerfile"), "FROM golang:1.22\n")
    end

    def write_project_protocols(project, project_path)
      protocol = project.create_protocol!(status: "draft")
      protocol.documents.create!(
        key: "agents_root",
        path: "AGENTS.md",
        title: "AGENTS",
        layer: "behavioral",
        position: 0,
        body: "Use Conventional Commits and run go test ./....",
        provenance: {"source" => "test"}
      )
      protocol.documents.create!(
        key: "conventions",
        path: ".agents/CONVENTIONS.md",
        title: "Conventions",
        layer: "behavioral",
        position: 1,
        body: "Keep generated protocol files out of repository filesystem context.",
        provenance: {"source" => "test"}
      )
      ProjectProtocols::FilesystemMaterializer.new(project: project, workspace_path: project_path).call
    end

    def write_previous_interactions(ticket)
      store = PreviousInteractionStore.new(root: Dir.mktmpdir("redwright-context-composer-previous-interactions-"))
      store.append(
        ticket: ticket,
        request: request_payload(branch_name: "feature/todo-done"),
        request_payload: {"prompt" => "Try implementation"},
        response_payload: {"message" => "Patch main.go"},
        outcome: "retry",
        failure_summary: "first attempt missed invalid index handling",
        context_section_names: %w[ticket relevant_files tests]
      )
      store
    end
  end
end
