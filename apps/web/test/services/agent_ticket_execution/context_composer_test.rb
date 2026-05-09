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
          %w[ticket project repository_tree relevant_files tests operational_setup protocol_files protocol_model documents quizzes dumps previous_interactions],
          sections.keys
        )
        assert_equal "ticket_record", sections.fetch("ticket").authority
        assert_equal "workspace_filesystem", sections.fetch("relevant_files").authority
        assert_equal "project_protocol_model", sections.fetch("protocol_model").authority
        assert_equal "project_protocol_model", sections.fetch("protocol_files").authority
        assert_equal "project_documents", sections.fetch("documents").authority
        assert_equal "project_quiz_model", sections.fetch("quizzes").authority
        assert_equal "repository_dump_artifacts", sections.fetch("dumps").authority
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
        assert_equal "quizzes", sections.fetch("quizzes").metadata.fetch("context_layer")
        assert_equal "dumps", sections.fetch("dumps").metadata.fetch("context_layer")
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
        use_case = create_use_case(project: fixture.project, name: "Feature")
        other_use_case = create_use_case(project: fixture.project, name: "Other")
        fixture.ticket.update!(use_case: use_case)
        draft = create_document(project: fixture.project, title: "Feature Draft", body: "Draft body")
        scoped_draft = create_document(project: fixture.project, use_case: use_case, title: "Scoped Feature Draft", body: "Scoped draft body")
        create_document(project: fixture.project, use_case: use_case, artifact_type: "spec", title: "Feature Spec", body: "Spec body", source_draft: scoped_draft, editable: false)
        create_document(project: fixture.project, artifact_type: "plan_tracker", title: "Feature Plan", body: "Plan body", editable: false)
        other_draft = create_document(project: fixture.project, use_case: other_use_case, title: "Other Draft", body: "Other draft body")
        create_document(project: fixture.project, use_case: other_use_case, artifact_type: "spec", title: "Other Spec", body: "Other spec body", source_draft: other_draft, editable: false)
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
        assert_includes omitted_titles, "Other Spec"
        refute_includes selected_titles, "AGENTS"
        assert_includes protocol_files.content.map { |document| document.fetch("title") }, "AGENTS"
        assert_equal "document_context_inventory", documents.metadata.fetch("selection_source")
        assert_equal "matched_use_case:#{use_case.id}:spec", documents.metadata.fetch("selected_documents").find { |document| document.fetch("title") == "Feature Spec" }.fetch("selection_reason")
        assert_equal "unselected_artifact_type:draft", documents.metadata.fetch("omitted_documents").find { |document| document.fetch("title") == "Feature Draft" }.fetch("omission_reason")
        assert_equal "unmatched_use_case:#{other_use_case.id}", documents.metadata.fetch("omitted_documents").find { |document| document.fetch("title") == "Other Spec" }.fetch("omission_reason")
      end
    end

    test "selects quiz context by policy and use case" do
      with_agent_ticket_execution_workspace do |fixture|
        use_case = create_use_case(project: fixture.project, name: "Billing")
        other_use_case = create_use_case(project: fixture.project, name: "Support")
        fixture.ticket.update!(use_case: use_case)
        project_quiz = fixture.project.find_or_create_main_quiz!
        project_entry = project_quiz.entries.create!(question: "What is global?", answer: "Global answer.")
        project_entry.tag_with!("global")
        scoped_quiz = use_case.find_or_create_quiz!
        scoped_entry = scoped_quiz.entries.create!(question: "What is billing?", answer: "Billing answer.")
        scoped_entry.tag_with!("billing")
        skipped_entry = scoped_quiz.entries.create!(question: "What was skipped?", status: "skipped")
        other_quiz = other_use_case.find_or_create_quiz!
        other_entry = other_quiz.entries.create!(question: "What is support?", answer: "Support answer.")

        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        planning_context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge("context_policy" => "planning_default"),
          workspace: workspace
        )
        implementation_context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge("context_policy" => "implementation_default"),
          workspace: workspace
        )

        planning_quizzes = planning_context.context_sections.index_by(&:name).fetch("quizzes")
        implementation_quizzes = implementation_context.context_sections.index_by(&:name).fetch("quizzes")
        selected_entry_questions = planning_quizzes.content.fetch("entries").map { |entry| entry.fetch("question") }
        omitted_entry_questions = planning_quizzes.content.fetch("omitted_entries").map { |entry| entry.fetch("id") }

        assert_includes planning_quizzes.content.fetch("quizzes").map { |quiz| quiz.fetch("name") }, project_quiz.name
        assert_includes planning_quizzes.content.fetch("quizzes").map { |quiz| quiz.fetch("name") }, scoped_quiz.name
        refute_includes planning_quizzes.content.fetch("quizzes").map { |quiz| quiz.fetch("name") }, other_quiz.name
        assert_includes selected_entry_questions, "What is global?"
        assert_includes selected_entry_questions, "What is billing?"
        assert_includes omitted_entry_questions, skipped_entry.id
        assert_includes omitted_entry_questions, other_entry.id
        assert_equal ["billing"], planning_quizzes.content.fetch("entries").find { |entry| entry.fetch("question") == "What is billing?" }.fetch("tags")
        assert_equal "matched_use_case:#{use_case.id}:planning_default", planning_quizzes.metadata.fetch("selected_entries").find { |entry| entry.fetch("id") == scoped_entry.id }.fetch("selection_reason")
        assert_equal "unselected_status:skipped", planning_quizzes.metadata.fetch("omitted_entries").find { |entry| entry.fetch("id") == skipped_entry.id }.fetch("omission_reason")
        assert_equal "unmatched_use_case:#{other_use_case.id}", planning_quizzes.metadata.fetch("omitted_entries").find { |entry| entry.fetch("id") == other_entry.id }.fetch("omission_reason")
        assert_empty implementation_quizzes.content.fetch("quizzes")
        assert_equal "policy_excludes_quizzes:implementation_default", implementation_quizzes.metadata.fetch("omitted_entries").find { |entry| entry.fetch("id") == project_entry.id }.fetch("omission_reason")
      end
    end

    test "selects curated dump context by policy and topic relevance" do
      with_agent_ticket_execution_workspace do |fixture|
        write_dump_artifacts(fixture.project_path)
        fixture.ticket.update!(
          title: "Improve LLM context shaping",
          description: "Use curated context shaping dumps while planning the request context."
        )

        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        planning_context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge("context_policy" => "planning_default"),
          workspace: workspace
        )
        implementation_context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge("context_policy" => "implementation_default"),
          workspace: workspace
        )

        planning_dumps = planning_context.context_sections.index_by(&:name).fetch("dumps")
        implementation_dumps = implementation_context.context_sections.index_by(&:name).fetch("dumps")
        selected_paths = planning_dumps.content.fetch("dumps").map { |dump| dump.fetch("path") }
        omitted_paths = planning_dumps.content.fetch("omitted_dumps").map { |dump| dump.fetch("path") }

        assert_includes selected_paths, "ops/conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump.md"
        refute_includes selected_paths, "ops/conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump-raw.md"
        assert_includes omitted_paths, "ops/conv/dump/2026-05-09-unrelated-deployment-dump.md"
        assert_equal "dump_context_inventory", planning_dumps.metadata.fetch("selection_source")
        assert_equal "matched_ticket_topic:llm", planning_dumps.metadata.fetch("selected_dumps").first.fetch("selection_reason")
        assert_equal "no_topic_match", planning_dumps.metadata.fetch("omitted_dumps").find { |dump| dump.fetch("path") == "ops/conv/dump/2026-05-09-unrelated-deployment-dump.md" }.fetch("omission_reason")
        assert_empty implementation_dumps.content.fetch("dumps")
        assert_equal "policy_excludes_dumps:implementation_default", implementation_dumps.metadata.fetch("omitted_dumps").first.fetch("omission_reason")
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

    def write_dump_artifacts(project_path)
      dump_dir = File.join(project_path, "ops", "conv", "dump")
      FileUtils.mkdir_p(dump_dir)
      File.write(
        File.join(dump_dir, "2026-05-09-redwright-agent-ticket-llm-context-shaping-dump.md"),
        "# LLM Context Shaping Dump\n\nCurated notes about LLM context shaping and request planning.\n"
      )
      File.write(
        File.join(dump_dir, "2026-05-09-redwright-agent-ticket-llm-context-shaping-dump-raw.md"),
        "# Raw Dump\n\nThis raw dump must not be selected.\n"
      )
      File.write(
        File.join(dump_dir, "2026-05-09-unrelated-deployment-dump.md"),
        "# Deployment Dump\n\nCurated notes about deployment automation.\n"
      )
    end
  end
end
