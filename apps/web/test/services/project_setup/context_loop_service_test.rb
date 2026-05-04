require "test_helper"
require "tmpdir"
require "yaml"

module ProjectSetup
  class ContextLoopServiceTest < ActiveSupport::TestCase
    test "records a trunk slot answer and advances prompt intent" do
      session = context_session
      session.assign_setup_slot(key: "project_name", value: "pocket-ledger", source: "payload")
      session.assign_setup_slot(key: "description", value: "A compact ledger for local notes.", source: "payload")
      session.metadata = session.metadata.merge(
        "next_prompt_intent" => prompt_intent("project_type")
      )
      session.save!

      result = ContextLoopService.new(session: session).advance!(
        answer: "CLI",
        normalized_fields: {"project_type" => "cli"},
        source_channel: "telegram",
        request_id: "req-context-service-type"
      )

      assert result.ok?
      session.reload
      assert_equal "cli", session.setup_slot("project_type").fetch("value")
      assert_equal "language_runtime", session.metadata.fetch("next_prompt_intent").fetch("slot")
      assert_equal 1, session.turn_counter
      assert_equal "setup_slot:project_type", result.turn.question
      assert_equal "answer", result.turn.normalized_fields.fetch("setup_context_action")
      saga = session.metadata.fetch("setup_saga")
      assert_equal "collecting_context", saga.fetch("state")
      assert_equal "questionnaire", saga.fetch("stage")
      assert_equal "collecting", saga.fetch("status")
      assert_equal 1, saga.fetch("turns").length
      assert_equal "telegram", saga.dig("metadata", "source_channel")
      assert_equal false, saga.dig("metadata", "boundaries", "questionnaire", "creates_persistent_domain_artifacts")
      assert_equal "language_runtime", saga.fetch("questionnaire").fetch("next_prompt_intent").fetch("slot")
    end

    test "normalizes language runtime version from Go project context" do
      session = context_session
      session.assign_setup_slot(key: "project_name", value: "hanoitowers", source: "payload")
      session.assign_setup_slot(key: "description", value: "A CLI for Tower of Hanoi demonstrations.", source: "payload")
      session.assign_setup_slot(key: "project_type", value: "CLI tool in Go", source: "user_answer")
      session.metadata = session.metadata.merge(
        "next_prompt_intent" => prompt_intent("language_runtime")
      )
      session.save!

      result = ContextLoopService.new(session: session).advance!(
        answer: "1.26.2",
        normalized_fields: {},
        source_channel: "telegram",
        request_id: "req-context-service-go-runtime"
      )

      assert result.ok?
      slot = session.reload.setup_slot("language_runtime")
      assert_equal "1.26.2", slot.fetch("raw_value")
      assert_equal "Go 1.26.2", slot.fetch("value")
      assert_equal "semantic_normalizer", slot.fetch("source")
      assert_equal "deterministic fallback normalization", slot.fetch("normalization_reason")
      assert_equal "framework", session.metadata.fetch("next_prompt_intent").fetch("slot")
      assert_equal "Go 1.26.2", result.turn.normalized_fields.fetch("setup_context_value")
      assert_equal "1.26.2", result.turn.normalized_fields.fetch("setup_context_raw_value")
    end

    test "does not persist prompt confusion as framework or stack" do
      session = context_session
      session.assign_setup_slot(key: "project_name", value: "hanoitowers", source: "payload")
      session.assign_setup_slot(key: "description", value: "A CLI for Tower of Hanoi demonstrations.", source: "payload")
      session.assign_setup_slot(key: "project_type", value: "cli", source: "user_answer")
      session.assign_setup_slot(key: "language_runtime", value: "Go 1.26.2", source: "user_answer")
      session.metadata = session.metadata.merge(
        "next_prompt_intent" => prompt_intent("framework")
      )
      session.save!

      result = ContextLoopService.new(session: session).advance!(
        answer: "I don't understand what those colons mean",
        normalized_fields: {},
        source_channel: "telegram",
        request_id: "req-context-service-framework-confusion"
      )

      assert result.ok?
      session.reload
      framework = session.setup_slot("framework")
      assert_equal "ambiguous", framework.fetch("status")
      assert_equal "I don't understand what those colons mean", framework.fetch("raw_value")
      assert_equal "", framework.fetch("value")
      assert_equal "framework", session.metadata.fetch("next_prompt_intent").fetch("slot")
      assert_equal "Project setup needs a clearer answer.", result.summary

      completed = ContextLoopService.new(session: session).advance!(
        answer: "/done",
        normalized_fields: {},
        source_channel: "telegram",
        request_id: "req-context-service-framework-confusion-done"
      )

      assert completed.ok?
      assert_equal "go-1.26.2", session.reload.project.stack_slug
      assert_equal "Go 1.26.2", session.setup_slot("stack").fetch("value")
    end

    test "skip marks recommended slot and advances" do
      session = context_session
      session.assign_setup_slot(key: "project_name", value: "pocket-ledger", source: "payload")
      session.metadata = session.metadata.merge(
        "next_prompt_intent" => prompt_intent("description")
      )
      session.save!

      result = ContextLoopService.new(session: session).advance!(
        answer: "/skip",
        normalized_fields: {},
        source_channel: "telegram",
        request_id: "req-context-service-skip"
      )

      assert result.ok?
      session.reload
      assert_equal "skipped", session.setup_slot("description").fetch("status")
      assert_equal "project_type", session.metadata.fetch("next_prompt_intent").fetch("slot")
      assert_equal ["project_setup_turn_recorded", "project_setup_prompt_advanced"], result.effects.map { |effect| effect.fetch("type") }
    end

    test "done repeats blocking slot when project name is missing" do
      session = context_session
      session.metadata = session.metadata.merge(
        "next_prompt_intent" => prompt_intent("project_name")
      )
      session.save!

      assert_no_difference -> { Project.count } do
        result = ContextLoopService.new(session: session).advance!(
          answer: "/done",
          normalized_fields: {},
          source_channel: "telegram",
          request_id: "req-context-service-done-missing-name"
        )

        assert result.ok?
        assert_equal "Project setup still needs a project name.", result.summary
      end
      session.reload
      assert_equal "collecting_context", session.current_state
      assert_equal "project_name", session.metadata.fetch("next_prompt_intent").fetch("slot")
    end

    test "cancel records audit turn and leaves no project" do
      session = context_session

      assert_no_difference -> { Project.count } do
        result = ContextLoopService.new(session: session).advance!(
          answer: "/cancel",
          normalized_fields: {},
          source_channel: "telegram",
          request_id: "req-context-service-cancel"
        )

        assert result.ok?
        assert_equal "Project setup cancelled.", result.summary
      end
      session.reload
      assert_equal "cancelled", session.current_state
      assert_equal "cancelled_by_user", session.terminal_reason
      assert_equal 1, session.turn_counter
    end

    test "replays setup context request id without duplicate turns" do
      session = context_session
      session.assign_setup_slot(key: "project_name", value: "pocket-ledger", source: "payload")
      session.metadata = session.metadata.merge(
        "next_prompt_intent" => prompt_intent("description")
      )
      session.save!
      service = ContextLoopService.new(session: session)

      service.advance!(
        answer: "A compact ledger for local notes.",
        normalized_fields: {},
        source_channel: "telegram",
        request_id: "req-context-service-replay"
      )
      result = service.advance!(
        answer: "A compact ledger for local notes.",
        normalized_fields: {},
        source_channel: "telegram",
        request_id: "req-context-service-replay"
      )

      assert result.ok?
      assert_equal ["project_setup_turn_reused"], result.effects.map { |effect| effect.fetch("type") }
      assert_equal 1, session.reload.turn_counter
      assert_equal 1, session.project_setup_turns.count
    end

    test "completes setup and materializes project artifacts from compact trunk" do
      session = context_session
      session.assign_setup_slot(key: "project_name", value: "pocket-ledger", source: "payload")
      session.assign_setup_slot(key: "description", value: "A compact ledger for local notes.", source: "payload")
      session.assign_setup_slot(key: "project_type", value: "cli", source: "user_answer")
      session.assign_setup_slot(key: "language_runtime", value: "Ruby 3.4", source: "user_answer")
      session.assign_setup_slot(key: "framework", value: "none", source: "user_answer")
      session.metadata = session.metadata.merge(
        "next_prompt_intent" => prompt_intent("libraries")
      )
      session.save!

      result = ContextLoopService.new(session: session).advance!(
        answer: "Thor and SQLite",
        normalized_fields: {"libraries" => "Thor and SQLite"},
        source_channel: "telegram",
        request_id: "req-context-service-complete"
      )

      assert result.ok?
      session.reload
      assert_equal "completed", session.current_state
      assert_equal "completed_without_alignment", session.terminal_reason
      assert_equal "pocket-ledger", session.project.name
      assert_equal "ruby-3.4", session.project.stack_slug
      assert session.project.documents.exists?(title: "Project Setup Summary", artifact_type: "draft")
      assert_equal "draft", session.project.protocol_state.fetch("status")
      assert_equal "AGENTS.md", session.project.protocol_state.fetch("documents").first.fetch("path")
      assert_equal %w[backlog in_progress review approved merged], session.project.boards.first.columns.order(:position).pluck(:key)
      ticket = session.project.tickets_scope.find_by!(title: "Prepare initial implementation plan")
      assert_equal result.data.fetch("starter_ticket_id"), ticket.id
      assert_includes result.effects.map { |effect| effect.fetch("type") }, "setup_context_materialized"
      saga = session.metadata.fetch("setup_saga")
      assert_equal "completed", saga.fetch("state")
      assert_equal "ticket_operation", saga.fetch("stage")
      assert_equal "ready", saga.fetch("status")
      assert_equal "completed_without_alignment", saga.fetch("terminal_reason")
      assert_operator saga.fetch("turns").length, :>=, 1
      assert_equal true, saga.dig("metadata", "boundaries", "materialization", "creates_persistent_domain_artifacts")
      assert_equal "materialized_planned", saga.dig("metadata", "materialization", "status")
      assert_equal "completed", saga.fetch("questionnaire").fetch("status")
      assert_equal "materialized_planned", saga.fetch("materialization").fetch("status")
      assert_equal false, saga.fetch("initial_implementation").fetch("runnable")
      assert_equal "planned", saga.fetch("initial_implementation").fetch("status")
      assert_includes saga.fetch("initial_implementation").fetch("linked_ticket_ids"), ticket.id
      assert_equal "draft", saga.fetch("protocols").fetch("status")
      assert_equal "blocked", saga.fetch("runtime_containers").fetch("readiness")
      assert_equal "available", saga.fetch("ticket_operation").fetch("status")
    end

    test "creates starter implementation ticket for planned fallback" do
      session = context_session
      session.assign_setup_slot(key: "project_name", value: "starter-flow", source: "payload")
      session.assign_setup_slot(key: "description", value: "A small service for starter workflow coverage.", source: "payload")
      session.assign_setup_slot(key: "project_type", value: "api_service", source: "user_answer")
      session.assign_setup_slot(key: "language_runtime", value: "Ruby 3.4", source: "user_answer")
      session.assign_setup_slot(key: "framework", value: "Rails", source: "user_answer")
      session.metadata = session.metadata.merge(
        "next_prompt_intent" => prompt_intent("libraries")
      )
      session.save!

      result = ContextLoopService.new(session: session).advance!(
        answer: "SQLite",
        normalized_fields: {
          "libraries" => "SQLite",
          "runtime_container_profile" => "ephemeral_docker"
        },
        source_channel: "telegram",
        request_id: "req-context-service-starter-ticket"
      )

      assert result.ok?
      project = session.reload.project
      ticket = Ticket.find(result.data.fetch("starter_ticket_id"))
      assert_equal project.id, ticket.project_id
      assert_equal "Prepare initial implementation plan", ticket.title
      assert_equal "backlog", ticket.column.key
      assert_equal "agent-coder", ticket.assignee
      assert_equal ["Project Setup Summary"], ticket.documents.pluck(:title)
      assert_match "Materialization outcome: materialized_planned", ticket.description
      readiness_ticket = Ticket.find(result.data.fetch("runtime_containers_readiness_ticket_id"))
      assert_equal project.id, readiness_ticket.project_id
      assert_equal "Review Runtime Containers readiness", readiness_ticket.title
      assert_match "Readiness: blocked", readiness_ticket.description
      assert_equal "blocked", result.data.fetch("runtime_containers").fetch("readiness")
      assert_includes result.effects.map { |effect| effect.fetch("type") }, "setup_starter_ticket_written"
      assert_includes result.effects.map { |effect| effect.fetch("type") }, "runtime_containers_initialized"
      assert_includes result.effects.map { |effect| effect.fetch("type") }, "runtime_containers_readiness_ticket_written"
    end

    test "completion materializes every collected setup slot into rails state and metadata" do
      session = context_session
      session.assign_setup_slot(key: "project_name", value: "context-rich", source: "payload")
      session.assign_setup_slot(key: "description", value: "A local CLI with explicit setup context.", source: "payload")
      session.assign_setup_slot(key: "project_type", value: "cli", source: "user_answer")
      session.assign_setup_slot(key: "language_runtime", value: "Ruby 3.4", source: "user_answer")
      session.assign_setup_slot(key: "repository", value: "https://example.com/acme/context-rich.git", source: "user_answer")
      session.assign_setup_slot(key: "framework", value: "none", source: "user_answer")
      session.metadata = session.metadata.merge(
        "next_prompt_intent" => prompt_intent("libraries")
      )
      session.save!

      result = ContextLoopService.new(session: session).advance!(
        answer: "Thor, SQLite, layered services, conventional commits",
        normalized_fields: {
          "libraries" => "Thor and SQLite",
          "patterns" => "layered services",
          "conventions" => "conventional commits",
          "runtime_container_profile" => "ephemeral_docker",
          "agent_workflow_mode" => "agent_assisted"
        },
        source_channel: "telegram",
        request_id: "req-context-service-all-slots"
      )

      assert result.ok?
      project = session.reload.project
      expected_values = {
        "setup_context.project_name" => "context-rich",
        "setup_context.description" => "A local CLI with explicit setup context.",
        "setup_context.project_type" => "cli",
        "setup_context.language_runtime" => "Ruby 3.4",
        "setup_context.repository" => "https://example.com/acme/context-rich.git",
        "setup_context.framework" => "none",
        "setup_context.libraries" => "Thor and SQLite",
        "setup_context.patterns" => "layered services",
        "setup_context.conventions" => "conventional commits",
        "setup_context.runtime_container_profile" => "ephemeral_docker",
        "setup_context.agent_workflow_mode" => "agent_assisted",
        "setup_context.stack" => "Ruby 3.4"
      }
      actual_values = project.project_attributes.index_by(&:key).transform_values(&:value)
      expected_values.each do |key, value|
        assert_equal value, actual_values.fetch(key)
      end
      assert_equal "draft", result.data.fetch("protocols").fetch("status")
      assert_equal "AGENTS.md", result.data.fetch("protocols").fetch("documents").first.fetch("path")
      assert_equal ["ruby"], result.data.fetch("protocols_generation").fetch("stack_keys")
      materialized = session.metadata.fetch("materialized_setup_context")
      assert_equal "context-rich", materialized.fetch("slots").fetch("project_name").fetch("value")
      assert_equal "conventional commits", materialized.fetch("slots").fetch("conventions").fetch("value")
      assert_equal project.id, session.metadata.fetch("project_id")
      assert_equal result.data.fetch("project").fetch("repo_url"), session.metadata.fetch("materialized_repository_url")
      assert_equal "draft", session.metadata.fetch("protocols").fetch("status")
      assert_equal false, session.metadata.fetch("protocols_generation").fetch("fallback_used")
    end

    test "setup persists protocol fallback when stack coverage is missing" do
      session = context_session
      session.assign_setup_slot(key: "project_name", value: "unknown-protocol", source: "payload")
      session.assign_setup_slot(key: "description", value: "Fallback protocol coverage.", source: "payload")
      session.assign_setup_slot(key: "project_type", value: "cli", source: "user_answer")
      session.assign_setup_slot(key: "language_runtime", value: "Cobol 1.0", source: "user_answer")
      session.assign_setup_slot(key: "framework", value: "none", source: "user_answer")
      session.metadata = session.metadata.merge("next_prompt_intent" => prompt_intent("libraries"))
      session.save!

      result = ContextLoopService.new(session: session).advance!(
        answer: "standard library",
        normalized_fields: {"libraries" => "standard library"},
        source_channel: "telegram",
        request_id: "req-context-service-protocol-fallback"
      )

      assert result.ok?
      assert_equal true, result.data.fetch("protocols_generation").fetch("fallback_used")
      assert_includes result.data.fetch("protocols_generation").fetch("missing_stack_tokens"), "Cobol 1.0"
      architecture = session.reload.project.protocol_state.fetch("documents").find { |doc| doc.fetch("key") == "architecture" }
      assert_equal "generated_during_initialization", architecture.fetch("provenance").fetch("source")
    end

    test "completion replay reuses existing materialized rails state" do
      session = context_session
      session.assign_setup_slot(key: "project_name", value: "replay-rich", source: "payload")
      session.assign_setup_slot(key: "description", value: "A setup replay coverage project.", source: "payload")
      session.assign_setup_slot(key: "project_type", value: "cli", source: "user_answer")
      session.assign_setup_slot(key: "language_runtime", value: "Ruby 3.4", source: "user_answer")
      session.assign_setup_slot(key: "framework", value: "none", source: "user_answer")
      session.metadata = session.metadata.merge(
        "next_prompt_intent" => prompt_intent("libraries")
      )
      session.save!
      service = ContextLoopService.new(session: session)

      first = service.advance!(
        answer: "Thor and SQLite",
        normalized_fields: {"libraries" => "Thor and SQLite", "agent_workflow_mode" => "agent_assisted"},
        source_channel: "telegram",
        request_id: "req-context-service-completion-replay"
      )
      counts = materialized_counts(first.session.reload.project)

      replay = service.replay(request_id: "req-context-service-completion-replay")

      assert replay.ok?
      assert_equal ["project_setup_turn_reused", "project_setup_completion_reused"], replay.effects.map { |effect| effect.fetch("type") }
      assert_equal counts, materialized_counts(first.session.reload.project)
      assert_equal first.data.fetch("project").fetch("id"), replay.data.fetch("project").fetch("id")
      assert_equal first.data.fetch("board_id"), replay.data.fetch("board_id")
      assert_equal first.data.fetch("setup_summary_document_id"), replay.data.fetch("setup_summary_document_id")
      assert_equal first.data.fetch("starter_ticket_id"), replay.data.fetch("starter_ticket_id")
    end

    test "completion materializes local workspace and manifest for local setup" do
      with_local_projects_root do |projects_root|
        session = context_session
        session.assign_setup_slot(key: "project_name", value: "workspace-rich", source: "payload")
        session.assign_setup_slot(key: "description", value: "A CLI that writes local notes.", source: "payload")
        session.assign_setup_slot(key: "project_type", value: "cli", source: "user_answer")
        session.assign_setup_slot(key: "language_runtime", value: "Ruby 3.4", source: "user_answer")
        session.assign_setup_slot(key: "framework", value: "none", source: "user_answer")
        session.metadata = session.metadata.merge(
          "next_prompt_intent" => prompt_intent("libraries")
        )
        session.save!

        result = ContextLoopService.new(session: session).advance!(
          answer: "Thor and SQLite",
          normalized_fields: {
            "libraries" => "Thor and SQLite",
            "patterns" => "service objects",
            "conventions" => "conventional commits"
          },
          source_channel: "telegram",
          request_id: "req-context-service-workspace"
        )

        assert result.ok?
        workspace = result.data.fetch("workspace")
        manifest_path = workspace.fetch("manifest_path")
        assert_equal File.join(projects_root, "workspace-rich"), workspace.fetch("path")
        assert_equal "_workspace/Projects/workspace-rich", workspace.fetch("relative_path")
        assert_equal "/workspace/projects/workspace-rich", workspace.fetch("runtime_root_path")
        assert File.directory?(workspace.fetch("path"))
        assert File.file?(manifest_path)

        manifest = YAML.safe_load(File.read(manifest_path))
        assert_equal 1, manifest.fetch("schema_version")
        assert_equal "workspace-rich", manifest.dig("project", "name")
        assert_equal "rails_project_setup", manifest.dig("project", "created_via")
        assert_equal result.session.project.id, manifest.dig("rails", "project_id")
        assert_equal "/workspace/projects/workspace-rich", manifest.dig("rails", "root_path")
        assert_equal "Ruby 3.4", manifest.dig("setup_context", "slots", "language_runtime", "value")
        assert_equal "Thor and SQLite", manifest.dig("setup_context", "slots", "libraries", "value")
        assert_equal "service objects", manifest.dig("setup_context", "slots", "patterns", "value")
        assert_equal "materialized_planned", manifest.dig("materialization", "status")
        assert_equal false, manifest.dig("materialization", "runnable")
        assert_equal "no runnable scaffold profile exists for this setup context yet", manifest.dig("materialization", "reason")
        assert_equal "planned", manifest.dig("initial_implementation", "status")
        assert_equal result.data.fetch("starter_ticket_id"), manifest.dig("initial_implementation", "linked_ticket_ids").first
        assert_equal "skipped", manifest.dig("validation", "status")
        assert_equal "materialized", manifest.dig("protocols", "status")
        assert_equal "AGENTS.md", manifest.dig("protocols", "root_entrypoint")
        assert_equal "draft", manifest.dig("protocols", "state", "status")
        assert_equal result.data.fetch("runtime_containers").fetch("id"), manifest.dig("runtime_containers", "runtime_container_id")
        assert_equal "blocked", manifest.dig("runtime_containers", "state", "readiness")
        assert_equal result.data.fetch("runtime_containers_readiness_ticket_id"), manifest.dig("runtime_containers", "readiness_ticket_id")
        assert File.file?(File.join(workspace.fetch("path"), "AGENTS.md"))
        assert File.file?(File.join(workspace.fetch("path"), ".agents", "CONVENTIONS.md"))
        assert File.file?(File.join(workspace.fetch("path"), ".agents", "ARCHITECTURE.md"))
        assert File.file?(File.join(workspace.fetch("path"), ".agents", "PLAYBOOKS.md"))
        assert File.file?(File.join(workspace.fetch("path"), ".agents", "playbooks", "slice-delivery.md"))
        assert File.file?(workspace.fetch("readme_path"))
        assert File.file?(workspace.fetch("setup_notes_path"))
        assert_equal "materialized", workspace.fetch("protocol_materialization_status")
        assert_equal "AGENTS.md", workspace.fetch("protocol_files").first.fetch("path")
        assert_includes File.read(workspace.fetch("readme_path")), "Materialization: materialized_planned"
        assert_includes File.read(workspace.fetch("setup_notes_path")), "Initial implementation status: planned"
        assert_equal workspace, result.session.metadata.fetch("workspace")
        assert_includes result.effects.map { |effect| effect.fetch("type") }, "local_workspace_materialized"
      end
    end

    test "local workspace materialization is idempotent" do
      with_local_projects_root do
        session = context_session
        session.assign_setup_slot(key: "project_name", value: "workspace-replay", source: "payload")
        session.metadata = session.metadata.merge(
          "next_prompt_intent" => prompt_intent("description")
        )
        session.save!
        service = ContextLoopService.new(session: session)

        first = service.advance!(
          answer: "/done",
          normalized_fields: {},
          source_channel: "telegram",
          request_id: "req-context-service-workspace-replay"
        )
        manifest_path = first.data.fetch("workspace").fetch("manifest_path")
        readme_path = first.data.fetch("workspace").fetch("readme_path")
        setup_notes_path = first.data.fetch("workspace").fetch("setup_notes_path")
        first_manifest = File.read(manifest_path)
        first_readme = File.read(readme_path)
        first_setup_notes = File.read(setup_notes_path)

        replay = service.replay(request_id: "req-context-service-workspace-replay")

        assert replay.ok?
        assert_equal first.data.fetch("workspace"), replay.data.fetch("workspace")
        assert_equal first_manifest, File.read(manifest_path)
        assert_equal first_readme, File.read(readme_path)
        assert_equal first_setup_notes, File.read(setup_notes_path)
        assert_equal ["project_setup_turn_reused", "project_setup_completion_reused"], replay.effects.map { |effect| effect.fetch("type") }
      end
    end

    test "go cli setup materializes scaffold files and validation outcome" do
      with_local_projects_root do |projects_root|
        session = context_session
        session.assign_setup_slot(key: "project_name", value: "hanoi-cli", source: "payload")
        session.assign_setup_slot(key: "description", value: "A CLI that solves Tower of Hanoi.", source: "payload")
        session.assign_setup_slot(key: "project_type", value: "CLI", source: "user_answer")
        session.assign_setup_slot(key: "language_runtime", value: "Go 1.22", source: "user_answer")
        session.assign_setup_slot(key: "framework", value: "none", source: "user_answer")
        session.metadata = session.metadata.merge(
          "next_prompt_intent" => prompt_intent("libraries")
        )
        session.save!

        result = ContextLoopService.new(session: session).advance!(
          answer: "standard library",
          normalized_fields: {"libraries" => "standard library"},
          source_channel: "telegram",
          request_id: "req-context-service-go-cli-scaffold"
        )

        assert result.ok?
        workspace = result.data.fetch("workspace")
        path = workspace.fetch("path")
        assert_equal File.join(projects_root, "hanoi-cli"), path
        assert_equal "go_cli", workspace.fetch("scaffold_profile")
        assert_equal %w[go.mod main.go main_test.go], workspace.fetch("scaffold_files")
        assert File.file?(File.join(path, "go.mod"))
        assert File.file?(File.join(path, "main.go"))
        assert File.file?(File.join(path, "main_test.go"))
        assert_includes File.read(File.join(path, "go.mod")), "module example.com/redwright/hanoi-cli"
        assert_includes File.read(File.join(path, "main.go")), "func main()"
        assert_includes File.read(File.join(path, "main_test.go")), "TestRunPrintsProjectName"

        manifest = YAML.safe_load(File.read(workspace.fetch("manifest_path")))
        assert_equal "go_cli", manifest.dig("scaffold", "profile")
        assert_equal "example.com/redwright/hanoi-cli", manifest.dig("scaffold", "module_path")
        assert_equal %w[go.mod main.go main_test.go], manifest.dig("scaffold", "files")
        assert_equal "go_cli", result.data.fetch("runtime_containers").fetch("profile")
        assert_equal "generated", result.data.fetch("runtime_containers").fetch("readiness")
        assert_equal "go_cli", manifest.dig("runtime_containers", "state", "profile")
        assert_equal result.data.fetch("runtime_containers_readiness_ticket_id"), manifest.dig("runtime_containers", "readiness_ticket_id")
        assert_equal "go test ./...", manifest.dig("validation", "command")
        assert_includes %w[passed skipped failed], manifest.dig("validation", "status")
        assert_equal manifest.dig("validation", "status"), workspace.fetch("validation_status")
        assert_equal manifest.dig("materialization", "runnable"), workspace.fetch("runnable")
        assert_equal manifest.dig("materialization", "status"), session.reload.metadata.fetch("setup_saga").fetch("materialization").fetch("status")
        assert_includes File.read(workspace.fetch("readme_path")), "go run ."
      end
    end

    test "go cli setup records urfave cli dependency without external validation" do
      with_local_projects_root do
        session = context_session
        session.assign_setup_slot(key: "project_name", value: "cobraless-cli", source: "payload")
        session.assign_setup_slot(key: "description", value: "A CLI that exercises optional library scaffolding.", source: "payload")
        session.assign_setup_slot(key: "project_type", value: "CLI", source: "user_answer")
        session.assign_setup_slot(key: "language_runtime", value: "Go 1.22", source: "user_answer")
        session.assign_setup_slot(key: "framework", value: "none", source: "user_answer")
        session.metadata = session.metadata.merge(
          "next_prompt_intent" => prompt_intent("libraries")
        )
        session.save!

        result = ContextLoopService.new(session: session).advance!(
          answer: "urfave/cli",
          normalized_fields: {"libraries" => "urfave/cli"},
          source_channel: "telegram",
          request_id: "req-context-service-go-cli-urfave"
        )

        assert result.ok?
        workspace = result.data.fetch("workspace")
        path = workspace.fetch("path")
        assert_includes File.read(File.join(path, "go.mod")), "require github.com/urfave/cli/v2"
        assert_includes File.read(File.join(path, "main.go")), "\"github.com/urfave/cli/v2\""
        manifest = YAML.safe_load(File.read(workspace.fetch("manifest_path")))
        assert_equal ["github.com/urfave/cli/v2"], manifest.dig("scaffold", "dependencies")
        assert_equal "skipped", manifest.dig("validation", "status")
        assert_equal "validation is skipped for scaffold profiles with external dependencies", manifest.dig("validation", "reason")
      end
    end

    private

    def context_session
      ProjectSetupSession.create!(
        actor_identifier: "telegram:chat:9:user:77",
        request_id: "req-context-service-#{SecureRandom.hex(4)}",
        source_channel: "telegram"
      )
    end

    def prompt_intent(slot)
      {
        "kind" => "setup_slot_question",
        "slot" => slot,
        "locale" => "auto",
        "llm_required" => true
      }
    end

    def materialized_counts(project)
      {
        projects: Project.where(id: project.id).count,
        attributes: project.project_attributes.count,
        documents: project.documents.count,
        boards: project.boards.count,
        columns: project.boards.sum { |board| board.columns.count },
        tickets: project.tickets_scope.count,
        links: TicketDocumentLink.joins(:ticket).where(tickets: {board_id: project.boards.select(:id)}).count
      }
    end

    def with_local_projects_root
      previous = ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"]
      Dir.mktmpdir("redwright-local-projects-") do |dir|
        ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"] = dir
        yield dir
      ensure
        if previous.nil?
          ENV.delete("REDWRIGHT_LOCAL_PROJECTS_ROOT")
        else
          ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"] = previous
        end
      end
    end
  end
end
