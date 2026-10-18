require "test_helper"
require "tmpdir"

module AgentTicketExecution
  class ContextComposerTest < ActiveSupport::TestCase
    test "composes ticket execution context sections for the request engine" do
      with_agent_ticket_execution_workspace do |fixture|
        write_runtime_setup(fixture.project_path)
        write_project_protocols(fixture.project, fixture.project_path)
        use_case = create_use_case(project: fixture.project, name: "Done command")
        fixture.ticket.update!(use_case: use_case)
        create_document(project: fixture.project, use_case: use_case, artifact_type: "spec", title: "Implementation Spec", body: "Spec body")
        create_document(project: fixture.project, use_case: use_case, artifact_type: "plan_tracker", title: "Implementation Plan", body: "Plan body")
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
          %w[ticket project repository_tree relevant_files tests operational_setup tree_sitter protocol_files documents quizzes dumps llm_based_context previous_interactions],
          sections.keys
        )
        assert_equal "ticket_record", sections.fetch("ticket").authority
        assert_equal "workspace_filesystem", sections.fetch("relevant_files").authority
        assert_equal "project_protocol_files", sections.fetch("protocol_files").authority
        assert_equal "workspace_semantic_parser", sections.fetch("tree_sitter").authority
        assert_equal "project_documents", sections.fetch("documents").authority
        assert_equal "project_quiz_model", sections.fetch("quizzes").authority
        assert_equal "repository_dump_artifacts", sections.fetch("dumps").authority
        assert_equal "llm_derived_summary", sections.fetch("llm_based_context").authority
        assert_equal "historical_conversation", sections.fetch("previous_interactions").authority
        assert_includes sections.fetch("ticket").content.fetch("description"), "done <task-number>"
        assert_includes sections.fetch("repository_tree").content.fetch("entries").map { |entry| entry.fetch("path") }, "main.go"
        refute_includes sections.fetch("repository_tree").content.fetch("entries").map { |entry| entry.fetch("path") }, "AGENTS.md"
        refute_includes sections.fetch("repository_tree").content.fetch("entries").map { |entry| entry.fetch("path") }, ".agents/CONVENTIONS.md"
        assert_includes sections.fetch("relevant_files").content.map { |file| file.fetch("path") }, "main.go"
        refute_includes sections.fetch("relevant_files").content.map { |file| file.fetch("path") }, "AGENTS.md"
        refute_includes sections.fetch("relevant_files").content.map { |file| file.fetch("path") }, ".agents/CONVENTIONS.md"
        assert_includes sections.fetch("tests").content.map { |file| file.fetch("path") }, "main_test.go"
        assert_equal "available", sections.fetch("operational_setup").content.fetch("status")
        assert_equal "prompt", sections.fetch("ticket").metadata.fetch("context_layer")
        assert_equal "project", sections.fetch("project").metadata.fetch("context_layer")
        assert_equal "file_tree", sections.fetch("repository_tree").metadata.fetch("context_layer")
        assert_equal "concrete_files", sections.fetch("relevant_files").metadata.fetch("context_layer")
        assert_equal "concrete_files", sections.fetch("tests").metadata.fetch("context_layer")
        assert_equal "agent", sections.fetch("operational_setup").metadata.fetch("context_layer")
        assert_equal "tree_sitter", sections.fetch("tree_sitter").metadata.fetch("context_layer")
        assert_includes sections.fetch("tree_sitter").content.fetch("files").map { |file| file.fetch("language") }, "go"
        assert sections.fetch("tree_sitter").content.fetch("symbols").any? { |symbol| symbol.fetch(:path) == "main.go" && symbol.fetch(:name) == "run" }
        assert sections.fetch("tree_sitter").content.fetch("symbols").any? { |symbol| symbol.fetch(:path) == "main.go" && symbol.fetch(:kind) == "type" && symbol.fetch(:name) == "Task" }
        assert_includes sections.fetch("protocol_files").content.map { |file| file.fetch("path") }, "AGENTS.md"
        assert_includes sections.fetch("protocol_files").content.map { |file| file.fetch("path") }, ".agents/CONVENTIONS.md"
        assert_includes sections.fetch("protocol_files").content.first.fetch("content"), "Use Conventional Commits"
        assert_equal "docs", sections.fetch("documents").metadata.fetch("context_layer")
        assert_includes sections.fetch("documents").content.fetch("documents").map { |document| document.fetch("title") }, "Implementation Spec"
        assert_includes sections.fetch("documents").content.fetch("documents").map { |document| document.fetch("title") }, "Implementation Plan"
        assert_empty sections.fetch("documents").content.fetch("omitted_documents")
        assert_equal "quizzes", sections.fetch("quizzes").metadata.fetch("context_layer")
        assert_equal "dumps", sections.fetch("dumps").metadata.fetch("context_layer")
        assert_equal "llm_based", sections.fetch("llm_based_context").metadata.fetch("context_layer")
        assert_equal "derived_from_agent_llm_interactions", sections.fetch("llm_based_context").metadata.fetch("authority")
        assert_equal "previous_interaction_created_at", sections.fetch("llm_based_context").metadata.fetch("freshness_source")
        assert_includes sections.fetch("llm_based_context").content.fetch("prior_attempt_summaries").first.fetch("derived_summary"), "failure=first attempt missed invalid index handling"
        assert_equal false, sections.fetch("llm_based_context").metadata.fetch("freshness").fetch("stale")
        assert_equal "conversation", sections.fetch("previous_interactions").metadata.fetch("context_layer")
        assert_equal false, sections.fetch("previous_interactions").content.fetch("human_chat_included")
        assert_equal 1, sections.fetch("previous_interactions").content.fetch("records").length
        assert_equal 1, sections.fetch("previous_interactions").metadata.fetch("agent_llm_records")

        assert_equal sections.keys, context.diagnostics.fetch("section_names")
        assert_operator context.diagnostics.fetch("context_bytes"), :>, 0
        assert_equal fixture.ticket.id, context.trace_metadata.fetch(:ticket_id)
        assert_equal fixture.project_path, context.trace_metadata.fetch(:project_root)
        assert_equal "test", context.trace_metadata.fetch(:source_channel)
        assert_equal "agent-test", context.trace_metadata.fetch(:actor_identifier)
        assert_equal context.context_sections, context.llm_request_inputs.fetch(:context_sections)
      end
    end

    test "marks validation feedback as prompt context for retry policy selection" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge(
            "validation_feedback" => {
              "stage" => "validation",
              "result" => "failed",
              "output" => "go test ./... failed"
            }
          ),
          workspace: workspace
        )

        feedback = context.context_sections.index_by(&:name).fetch("validation_feedback")

        assert_equal "current_execution_feedback", feedback.authority
        assert_equal "prompt", feedback.metadata.fetch("context_layer")
      end
    end

    test "keeps llm derived context distinct from primary artifacts" do
      with_agent_ticket_execution_workspace do |fixture|
        store = write_previous_interactions(fixture.ticket)

        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        context = ContextComposer.new(previous_interaction_store: store).compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge("context_policy" => "diagnosis_default"),
          workspace: workspace
        )

        derived_context = context.context_sections.index_by(&:name).fetch("llm_based_context")
        summary = derived_context.content.fetch("prior_attempt_summaries").first

        assert_equal "llm_based", derived_context.metadata.fetch("context_layer")
        assert_equal "previous_interaction_store", derived_context.metadata.fetch("selection_source")
        assert_equal "agent_llm_previous_interaction", summary.fetch("source")
        assert_equal fixture.ticket.id, summary.fetch("ticket_id")
        assert_equal "retry", summary.fetch("outcome")
        assert_equal %w[ticket relevant_files tests], summary.fetch("context_section_names")
        refute_includes summary.keys, "request_payload"
        refute_includes summary.keys, "response_payload"
      end
    end

    test "selects human and agent conversation context without losing agent interaction replay" do
      with_agent_ticket_execution_workspace do |fixture|
        use_case = create_use_case(project: fixture.project, name: "Done Workflow")
        fixture.ticket.update!(use_case: use_case)
        same_ticket_comment = fixture.ticket.ticket_comments.create!(
          author_type: "user",
          author_label: "Telegram User",
          author_handle: "telegram:9001",
          body: "Please keep the done command behavior explicit."
        )
        same_use_case_ticket = Ticket.create!(
          board: fixture.board,
          column: fixture.columns.fetch("backlog"),
          use_case: use_case,
          title: "Refine done workflow",
          description: "Related use-case discussion.",
          assignee: "agent-coder",
          kind: "task",
          severity: "low",
          scope: "runtime",
          source: "implementation"
        )
        use_case_comment = same_use_case_ticket.ticket_comments.create!(
          author_type: "agent",
          author_label: "Agent",
          body: "Use the same use case constraints for done workflow changes."
        )
        project_ticket = Ticket.create!(
          board: fixture.board,
          column: fixture.columns.fetch("backlog"),
          title: "Project topic note",
          description: "Project-level conversation.",
          assignee: "agent-coder",
          kind: "task",
          severity: "low",
          scope: "runtime",
          source: "implementation"
        )
        project_comment = project_ticket.ticket_comments.create!(
          author_type: "user",
          author_label: "TUI User",
          body: "The done command context should be reused across implementation work."
        )
        unrelated_ticket = Ticket.create!(
          board: fixture.board,
          column: fixture.columns.fetch("backlog"),
          title: "Unrelated deployment note",
          description: "No relevant overlap.",
          assignee: "agent-coder",
          kind: "task",
          severity: "low",
          scope: "infra",
          source: "implementation"
        )
        unrelated_comment = unrelated_ticket.ticket_comments.create!(
          author_type: "user",
          author_label: "Web User",
          body: "Deployment credentials should stay isolated."
        )
        store = write_previous_interactions(fixture.ticket)

        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        context = ContextComposer.new(previous_interaction_store: store).compose(
          ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge("context_policy" => "implementation_default"),
          workspace: workspace
        )

        previous_interactions = context.context_sections.index_by(&:name).fetch("previous_interactions")
        selected_comment_ids = previous_interactions.content.fetch("ticket_comments").map { |comment| comment.fetch("id") }
        omitted_comment_ids = previous_interactions.content.fetch("omitted_ticket_comments").map { |comment| comment.fetch("id") }

        assert_equal true, previous_interactions.content.fetch("human_chat_included")
        assert_includes selected_comment_ids, same_ticket_comment.id
        assert_includes selected_comment_ids, use_case_comment.id
        assert_includes selected_comment_ids, project_comment.id
        assert_includes omitted_comment_ids, unrelated_comment.id
        assert_equal "matched_ticket:#{fixture.ticket.id}", previous_interactions.metadata.fetch("selected_ticket_comments").find { |comment| comment.fetch("id") == same_ticket_comment.id }.fetch("selection_reason")
        assert_equal "matched_use_case:#{use_case.id}", previous_interactions.metadata.fetch("selected_ticket_comments").find { |comment| comment.fetch("id") == use_case_comment.id }.fetch("selection_reason")
        assert_equal "no_conversation_scope_match", previous_interactions.metadata.fetch("omitted_ticket_comments").find { |comment| comment.fetch("id") == unrelated_comment.id }.fetch("omission_reason")
        assert_equal "operational", previous_interactions.content.fetch("storage_inventory").fetch("ticket_comments").fetch("status")
        assert_equal 1, previous_interactions.content.fetch("records").length
        assert_equal previous_interactions.content.fetch("records"), previous_interactions.content.fetch("agent_llm_records")
      end
    end

    test "selects protocol files by policy" do
      with_agent_ticket_execution_workspace do |fixture|
        write_protocol_files(project: fixture.project, documents: [
          {path: "AGENTS.md", body: "Root instructions."},
          {path: ".agents/stacks/custom/RUNTIME.md", body: "Runtime stack instructions."}
        ])

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
        assert_equal %w[AGENTS.md .agents/stacks/custom/RUNTIME.md], implementation_protocols.content.map { |document| document.fetch("path") }
        assert_equal ["AGENTS.md"], planning_protocols.content.map { |document| document.fetch("path") }
        assert_equal "protocols", implementation_protocols.metadata.fetch("context_layer")
        assert_equal "project_protocol_files", implementation_protocols.metadata.fetch("selected_protocol_documents").last.fetch("provenance").fetch("source")
      end
    end

    test "selects document context separately from protocols" do
      with_agent_ticket_execution_workspace do |fixture|
        use_case = create_use_case(project: fixture.project, name: "Feature")
        other_use_case = create_use_case(project: fixture.project, name: "Other")
        fixture.ticket.update!(use_case: use_case)
        draft = create_document(project: fixture.project, use_case: use_case, title: "Feature Draft", status: "draft", body: "Draft body")
        create_document(project: fixture.project, use_case: use_case, artifact_type: "plan_tracker", title: "Feature Plan", body: "Plan body")
        create_document(project: fixture.project, use_case: other_use_case, artifact_type: "spec", title: "Other Spec", body: "Other spec body")
        write_project_protocols(fixture.project, fixture.project_path)

        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        draft_context = ContextComposer.new.compose(ticket: fixture.ticket,
          request: request_payload(branch_name: "feature/todo-done").merge("context_policy" => "implementation_default"), workspace: workspace)
        omitted = draft_context.context_sections.index_by(&:name).fetch("documents").content.fetch("omitted_documents")
        assert_equal "specification_not_approved", omitted.find { |document| document.fetch("title") == "Feature Draft" }.fetch("omission_reason")
        draft.update!(title: "Feature Spec", status: "approved", body: "Spec body")
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
        assert_includes omitted_titles, "Other Spec"
        refute_includes selected_titles, "AGENTS"
        assert_includes protocol_files.content.map { |document| document.fetch("title") }, "AGENTS"
        assert_equal "document_context_inventory", documents.metadata.fetch("selection_source")
        assert_equal "matched_use_case:#{use_case.id}:spec", documents.metadata.fetch("selected_documents").find { |document| document.fetch("title") == "Feature Spec" }.fetch("selection_reason")
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
        use_case = create_use_case(project: fixture.project, name: "LLM Billing")
        fixture.ticket.update!(use_case: use_case)
        database_dump = fixture.project.dumps.create!(
          use_case: use_case,
          title: "Billing LLM Context Dump",
          summary: "Curated billing LLM context.",
          curated_body: "# Billing LLM Context\n\nUse billing-specific LLM context.",
          curation_status: "curated",
          capture_status: "closed",
          status: "completed"
        )
        database_dump.tag_with!("billing", "llm")
        active_dump = fixture.project.dumps.create!(
          title: "Active LLM Draft Dump",
          raw_body: "Draft LLM context that should not be selected."
        )
        active_dump.tag_with!("llm")
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
        assert_includes selected_paths, "database:dumps/#{database_dump.slug}"
        refute_includes selected_paths, "ops/conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump-raw.md"
        assert_includes omitted_paths, "ops/conv/dump/2026-05-09-unrelated-deployment-dump.md"
        assert_includes omitted_paths, "database:dumps/#{active_dump.slug}"
        assert_equal "dump_context_inventory", planning_dumps.metadata.fetch("selection_source")
        assert_equal "matched_ticket_topic:llm", planning_dumps.metadata.fetch("selected_dumps").first.fetch("selection_reason")
        assert_equal "no_topic_match", planning_dumps.metadata.fetch("omitted_dumps").find { |dump| dump.fetch("path") == "ops/conv/dump/2026-05-09-unrelated-deployment-dump.md" }.fetch("omission_reason")
        assert_equal "uncurated_or_active_dump", planning_dumps.metadata.fetch("omitted_dumps").find { |dump| dump.fetch("path") == "database:dumps/#{active_dump.slug}" }.fetch("omission_reason")
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
      write_protocol_files(project: project, documents: [
        {path: "AGENTS.md", body: "Use Conventional Commits and run go test ./...."},
        {path: ".agents/CONVENTIONS.md", body: "Keep protocol files out of repository filesystem context."}
      ])
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
