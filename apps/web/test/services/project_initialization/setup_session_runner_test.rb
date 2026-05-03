require "test_helper"

module ProjectInitialization
  class SetupSessionRunnerTest < ActiveSupport::TestCase
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
        assert_equal "Which stack or framework should this project use? Reply /skip if undecided.", session.pending_question
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
        assert_equal "What should we call this project?", session.pending_question
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
      )
      command = build_command(slug: "inventory-duplicate", guided_alignment: true)

      assert_no_difference -> { Project.count } do
        result = run_command(command)

        assert_equal :initialization_failed, result.status
        session = result.setup_session.reload
        assert_equal "failed", session.status
        assert_equal "failed", session.current_state
        assert_equal "failed_reconciled", session.terminal_reason
        assert_nil session.project
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

    def run_command(command)
      SetupSessionRunner.new(
        command: command,
        actor_identifier: "web:user@example.com",
        request_id: "req-#{SecureRandom.hex(4)}",
        source_channel: "web"
      ).call
    end
  end
end
