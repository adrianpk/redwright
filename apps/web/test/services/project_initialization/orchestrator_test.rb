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

    test "returns repository resolution required for valid command" do
      command = Command.new(
        project_name: "InventoryService",
        directory_name: "inventory-service",
        repository_input: "git@codeberg.org:acme/inventory-service.git",
        guided_alignment: false
      )

      result = Orchestrator.new(command: command).call

      assert_equal :repository_resolution_required, result.status
      assert_equal :resolve_repository, result.next_action
      assert_equal "InventoryService", result.project[:name]
      assert_equal "inventory-service", result.project[:directory_name]
      assert_equal "git@codeberg.org:acme/inventory-service.git", result.repository[:input]
      assert_equal false, result.guided_alignment[:requested]
      assert_equal({}, result.errors)
    end

    test "result shape is deterministic for integration callers" do
      command = Command.new(
        project_name: "InventoryService",
        directory_name: "inventory-service",
        repository_input: "inventory-service"
      )

      payload = Orchestrator.new(command: command).call.to_h
      assert_equal(
        %i[status next_action project repository guided_alignment errors],
        payload.keys
      )
    end
  end
end
