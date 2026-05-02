require "test_helper"

module ProjectInitialization
  class OrchestratorTest < ActiveSupport::TestCase
    test "returns invalid_command result when command is invalid" do
      command = Command.new(project_name: "", directory_name: "", repository_input: "")

      result = Orchestrator.new(command: command).call

      assert_equal :invalid_command, result.status
      assert_equal :reject_command, result.next_action
      assert_equal "can't be blank", result.errors[:project_name]
      assert_equal({}, result.project)
      assert_equal({}, result.repository)
    end

    test "returns repository resolved for explicit repository input" do
      command = Command.new(
        project_name: "InventoryService",
        directory_name: "inventory-service",
        repository_input: "git@codeberg.org:acme/inventory-service.git",
        guided_alignment: false
      )

      result = Orchestrator.new(command: command).call

      assert_equal :repository_resolved, result.status
      assert_equal :confirm_repository, result.next_action
      assert_equal "git@codeberg.org:acme/inventory-service.git", result.repository[:canonical]
      assert_equal :explicit_url, result.repository[:source]
      assert_equal false, result.guided_alignment[:requested]
      assert_equal({}, result.errors)
    end

    test "returns focused clarification state for ambiguous repository input" do
      command = Command.new(
        project_name: "InventoryService",
        directory_name: "inventory-service",
        repository_input: "inventory-service"
      )

      result = Orchestrator.new(command: command).call

      assert_equal :repository_resolution_ambiguous, result.status
      assert_equal :clarify_repository, result.next_action
      assert_equal :unsupported_or_incomplete_repository_identifier, result.repository[:clarification][:reason]
    end

    test "returns cancellation state and guarantees no side effects" do
      command = Command.new(
        project_name: "InventoryService",
        directory_name: "inventory-service",
        repository_input: "cancel"
      )

      result = Orchestrator.new(command: command).call

      assert_equal :initialization_cancelled, result.status
      assert_equal :abort_initialization, result.next_action
      assert_equal false, result.project[:created]
      assert_equal false, result.repository[:created]
      assert_equal false, result.guided_alignment[:executed]
      assert_equal({}, result.errors)
    end

    test "result shape is deterministic for integration callers" do
      command = Command.new(
        project_name: "InventoryService",
        directory_name: "inventory-service",
        repository_input: "acme/inventory-service"
      )

      payload = Orchestrator.new(command: command).call.to_h
      assert_equal(
        %i[status next_action project repository guided_alignment errors],
        payload.keys
      )
    end
  end
end
