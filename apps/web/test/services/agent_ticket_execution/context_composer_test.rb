require "test_helper"
require "tmpdir"

module AgentTicketExecution
  class ContextComposerTest < ActiveSupport::TestCase
    test "composes ticket execution context sections for the request engine" do
      with_agent_ticket_execution_workspace do |fixture|
        write_runtime_setup(fixture.project_path)
        write_project_protocols(fixture.project, fixture.project_path)
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
          %w[ticket project repository_tree relevant_files tests operational_setup protocol_files protocol_model previous_interactions],
          sections.keys
        )
        assert_equal "ticket_record", sections.fetch("ticket").authority
        assert_equal "workspace_filesystem", sections.fetch("relevant_files").authority
        assert_equal "project_protocol_model", sections.fetch("protocol_model").authority
        assert_equal "historical_agent_llm_interaction", sections.fetch("previous_interactions").authority
        assert_includes sections.fetch("ticket").content.fetch("description"), "done <task-number>"
        assert_includes sections.fetch("repository_tree").content.fetch("entries").map { |entry| entry.fetch("path") }, "main.go"
        assert_includes sections.fetch("relevant_files").content.map { |file| file.fetch("path") }, "main.go"
        assert_includes sections.fetch("tests").content.map { |file| file.fetch("path") }, "main_test.go"
        assert_equal "available", sections.fetch("operational_setup").content.fetch("status")
        assert_includes sections.fetch("protocol_files").content.map { |file| file.fetch("path") }, "AGENTS.md"
        assert_equal false, sections.fetch("previous_interactions").content.fetch("human_chat_included")
        assert_equal 1, sections.fetch("previous_interactions").content.fetch("records").length

        assert_equal sections.keys, context.diagnostics.fetch("section_names")
        assert_operator context.diagnostics.fetch("context_bytes"), :>, 0
        assert_equal fixture.ticket.id, context.trace_metadata.fetch(:ticket_id)
        assert_equal fixture.project_path, context.trace_metadata.fetch(:project_root)
        assert_equal context.context_sections, context.llm_request_inputs.fetch(:context_sections)
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
