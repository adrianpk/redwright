require "test_helper"

module ProjectInitialization
  class ExecutorTest < ActiveSupport::TestCase
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

    test "returns initialization_completed when all steps succeed" do
      command = base_command
      lifecycle = LifecycleDouble.new

      result = Executor.new(
        command: command,
        resolved_repository: resolved_repository,
        lifecycle: lifecycle
      ).call

      assert_equal :initialization_completed, result.status
      assert_equal :initialization_done, result.next_action
      assert_equal true, result.repository[:created]
      assert_equal true, result.project[:created]
      assert_equal({}, result.errors)
    end

    test "returns initialization_failed when project creation fails and rollback succeeds" do
      command = base_command
      lifecycle = LifecycleDouble.new(failure_step: :project, rollback_status: :reconciled)

      result = Executor.new(
        command: command,
        resolved_repository: resolved_repository,
        lifecycle: lifecycle
      ).call

      assert_equal :initialization_failed, result.status
      assert_equal :report_failure, result.next_action
      assert_equal true, result.repository[:created]
      assert_equal false, result.project[:created]
      assert_equal "project failed", result.errors[:initialization][:message]
      assert_equal :reconciled, result.errors[:initialization][:reconciliation][:status]
    end

    test "returns initialization_incomplete when workspace fails and rollback is incomplete" do
      command = base_command
      lifecycle = LifecycleDouble.new(failure_step: :workspace, rollback_status: :incomplete)

      result = Executor.new(
        command: command,
        resolved_repository: resolved_repository,
        lifecycle: lifecycle
      ).call

      assert_equal :initialization_incomplete, result.status
      assert_equal :manual_reconciliation_required, result.next_action
      assert_equal true, result.repository[:created]
      assert_equal true, result.project[:created]
      assert_equal "workspace failed", result.errors[:initialization][:message]
      assert_equal :incomplete, result.errors[:initialization][:reconciliation][:status]
    end

    test "returns initialization_failed when repository fails and rollback succeeds" do
      command = base_command
      lifecycle = LifecycleDouble.new(failure_step: :repository, rollback_status: :reconciled)

      result = Executor.new(
        command: command,
        resolved_repository: resolved_repository,
        lifecycle: lifecycle
      ).call

      assert_equal :initialization_failed, result.status
      assert_equal false, result.repository[:created]
      assert_equal false, result.project[:created]
      assert_equal "repository failed", result.errors[:initialization][:message]
    end

    test "returns deterministic payload shape for incomplete outcomes" do
      command = base_command
      lifecycle = LifecycleDouble.new(failure_step: :workspace, rollback_status: :incomplete)

      payload = Executor.new(
        command: command,
        resolved_repository: resolved_repository,
        lifecycle: lifecycle
      ).call.to_h

      assert_equal(
        %i[status next_action project repository guided_alignment errors],
        payload.keys
      )
      assert_equal :initialization_incomplete, payload[:status]
    end

    private

    def base_command
      Command.new(
        project_name: "InventoryService",
        directory_name: "inventory-service",
        repository_input: "acme/inventory-service",
        guided_alignment: false
      )
    end

    def resolved_repository
      {
        canonical: "https://github.com/acme/inventory-service.git",
        source: :owner_repo
      }
    end
  end
end
