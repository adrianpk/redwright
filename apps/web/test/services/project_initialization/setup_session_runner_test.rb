require "test_helper"

module ProjectInitialization
  class SetupSessionRunnerTest < ActiveSupport::TestCase
    LifecycleDouble = Struct.new(:failure_step, :rollback_status, keyword_init: true) do
      def create_repository(command:, resolved_repository:)
        raise "repository failed" if failure_step == :repository

        {id: "repo-1", canonical: resolved_repository[:canonical], name: command.project_name}
      end

      def create_project(command:, repository:)
        raise "project failed" if failure_step == :project

        {id: "project-1", repository_id: repository[:id], name: command.project_name}
      end

      def create_workspace(command:, project:)
        raise "workspace failed" if failure_step == :workspace

        {id: "workspace-1", project_id: project[:id], directory_name: command.directory_name}
      end

      def rollback(context:, error:)
        {
          status: rollback_status || :reconciled,
          cleaned: {
            repository: !context[:repository].nil?,
            project: !context[:project].nil?,
            workspace: !context[:workspace].nil?
          },
          error: error.message
        }
      end
    end

    test "creates project and leaves setup session collecting alignment when guided alignment is requested" do
      command = build_command(slug: "inventory-alignment", guided_alignment: true)

      result = run_command(command)

      assert_equal :initialization_completed, result.status
      project = Project.find(result.project[:id])
      session = result.setup_session.reload
      assert_equal project, session.project
      assert_equal "open", session.status
      assert_equal "collecting_alignment", session.current_state
      assert_equal SetupSessionRunner::ALIGNMENT_QUESTION, session.pending_question
      assert_equal true, session.metadata["guided_alignment_pending"]
      assert_equal "guided_alignment_question", session.metadata.dig("next_prompt_intent", "kind")
      assert_equal "primary_outcome", session.metadata.dig("next_prompt_intent", "question_key")
      assert_equal SetupSessionRunner::ALIGNMENT_QUESTION, session.metadata.dig("next_prompt_intent", "metadata", "question_text")
      assert_equal "collecting_alignment", result.guided_alignment[:setup_state]
    end

    test "creates project and completes setup session when guided alignment is skipped" do
      command = build_command(slug: "inventory-no-alignment", guided_alignment: false)

      result = run_command(command)

      session = result.setup_session.reload
      assert_equal :initialization_completed, result.status
      assert_equal "completed", session.status
      assert_equal "completed", session.current_state
      assert_equal "completed_without_alignment", session.terminal_reason
      assert_nil session.pending_question
      assert_equal false, session.metadata["guided_alignment_pending"]
      assert_equal "completed", result.guided_alignment[:setup_state]
      assert_equal 0, session.project.project_attributes.count
      assert_equal 0, session.project.documents.count
    end

    test "persists cancellation without creating project" do
      command = build_command(slug: "inventory-cancelled", repository_input: "cancel")

      assert_no_difference -> { Project.count } do
        result = run_command(command)

        assert_equal :initialization_cancelled, result.status
        session = result.setup_session.reload
        assert_equal "cancelled", session.status
        assert_equal "cancelled", session.current_state
        assert_equal "cancelled_by_user", session.terminal_reason
        assert_nil session.project
      end
    end

    test "persists ambiguous repository state without creating project" do
      command = build_command(slug: "inventory-ambiguous", repository_input: "inventory-ambiguous")

      assert_no_difference -> { Project.count } do
        result = run_command(command)

        assert_equal :repository_resolution_ambiguous, result.status
        session = result.setup_session.reload
        assert_equal "open", session.status
        assert_equal "awaiting_repository", session.current_state
        assert_equal SetupSessionRunner::REPOSITORY_CLARIFICATION, session.pending_question
        assert_equal "repository_clarification_question", session.metadata.dig("next_prompt_intent", "kind")
        assert_equal SetupSessionRunner::REPOSITORY_CLARIFICATION, session.metadata.dig("next_prompt_intent", "metadata", "question_text")
        assert_nil session.project
      end
    end

    test "starts setup context collection without repository input" do
      command = Command.new(
        project_name: "Notes CLI",
        description: "A small local notes manager",
        repository_input: "",
        guided_alignment: true
      )

      assert_no_difference -> { Project.count } do
        result = run_command(command)

        assert_equal :setup_context_required, result.status
        session = result.setup_session.reload
        assert_equal "open", session.status
        assert_equal "collecting_context", session.current_state
        assert_nil session.pending_question
        assert_setup_slot_intent session.metadata.fetch("next_prompt_intent"), "project_type"
        assert_nil session.project
        assert_equal "Notes CLI", session.setup_slot(:project_name).fetch("value")
        assert_equal "A small local notes manager", session.setup_slot(:description).fetch("value")
        assert_nil session.setup_slot(:repository)
      end
    end

    test "starts setup context collection without project name" do
      command = Command.new(project_name: "", directory_name: "", repository_input: "")

      assert_no_difference -> { Project.count } do
        result = run_command(command)

        assert_equal :setup_context_required, result.status
        session = result.setup_session.reload
        assert_equal "collecting_context", session.current_state
        assert_nil session.pending_question
        assert_setup_slot_intent session.metadata.fetch("next_prompt_intent"), "project_name"
        assert_equal({}, session.setup_slots)
      end
    end

    test "rejects invalid command without hidden setup state" do
      command = Command.new(project_name: "Invalid", repository_input: "", guided_alignment: "yes")

      assert_no_difference -> { Project.count } do
        assert_no_difference -> { ProjectSetupSession.count } do
          result = run_command(command)

          assert_equal :invalid_command, result.status
          assert_nil result.setup_session
        end
      end
    end

    test "persists failed setup session without creating a duplicate project" do
      create_project(
        name: "Existing Inventory",
        key: "inventory-duplicate"
      ).update!(root_path: "/workspace/projects/inventory-duplicate")
      command = build_command(slug: "inventory-duplicate", guided_alignment: true)

      assert_no_difference -> { Project.count } do
        result = run_command(command)

        assert_equal :initialization_failed, result.status
        session = result.setup_session.reload
        assert_equal "failed", session.status
        assert_equal "failed", session.current_state
        assert_equal "failed_reconciled", session.terminal_reason
        assert_nil session.project
        saga = session.metadata.fetch("setup_saga")
        assert_equal "failed", saga.fetch("stage")
        assert_equal "failed", saga.fetch("status")
        assert_equal "failed", saga.fetch("materialization").fetch("status")
        failed_effect = saga.fetch("effects").find { |effect| effect.fetch("type") == "project_setup_failed" }
        assert_equal "public", failed_effect.fetch("visibility")
      end
    end

    test "persists needs_reconciliation saga state and preserved context when rollback is incomplete" do
      command = build_command(slug: "inventory-incomplete", guided_alignment: true)

      assert_no_difference -> { Project.count } do
        result = run_command(
          command,
          lifecycle: LifecycleDouble.new(failure_step: :workspace, rollback_status: :incomplete)
        )

        assert_equal :initialization_incomplete, result.status
        session = result.setup_session.reload
        assert_equal "needs_reconciliation", session.status
        assert_equal "needs_reconciliation", session.current_state
        assert_equal "failed_needs_reconciliation", session.terminal_reason
        saga = session.metadata.fetch("setup_saga")
        assert_equal "failed", saga.fetch("stage")
        assert_equal "needs_reconciliation", saga.fetch("status")
        assert_equal "needs_reconciliation", saga.fetch("materialization").fetch("status")
        assert_equal "incomplete", saga.dig("metadata", "materialization", "reconciliation", "status")
        assert_equal true, saga.dig("metadata", "materialization", "preserved_context", "setup_context", "slots").is_a?(Hash)
        reconciliation_effect = saga.fetch("effects").find { |effect| effect.fetch("type") == "project_setup_reconciliation_required" }
        assert_equal "public", reconciliation_effect.fetch("visibility")
      end
    end

    private

    def build_command(slug:, repository_input: nil, guided_alignment: false)
      Command.new(
        project_name: slug.titleize,
        directory_name: slug,
        repository_input: repository_input || "acme/#{slug}",
        guided_alignment: guided_alignment
      )
    end

    def run_command(command, lifecycle: ProjectInitialization::ActiveRecordLifecycle.new)
      SetupSessionRunner.new(
        command: command,
        actor_identifier: "web:user@example.com",
        request_id: "req-#{SecureRandom.hex(4)}",
        source_channel: "web",
        lifecycle: lifecycle
      ).call
    end

    def assert_setup_slot_intent(intent, slot)
      assert_equal "setup_slot_question", intent.fetch("kind")
      assert_equal slot, intent.fetch("slot")
      assert_equal "auto", intent.fetch("locale")
      assert_equal true, intent.fetch("llm_required")
      assert_equal slot, intent.dig("metadata", "semantic_contract", "slot")
      assert intent.dig("metadata", "semantic_contract", "intent").present?
    end
  end
end
