require "test_helper"

module ProjectInitialization
  class CommandTest < ActiveSupport::TestCase
    test "is valid with required fields and optional guided alignment" do
      command = Command.new(
        project_name: "InventoryService",
        directory_name: "inventory-service",
        repository_input: "git@codeberg.org:acme/inventory-service.git",
        guided_alignment: true
      )

      assert command.valid?
      assert_equal({}, command.errors)
    end

    test "allows sparse context before project creation" do
      command = Command.new(project_name: "", directory_name: "", repository_input: "")

      assert command.valid?
      assert_equal({}, command.errors)
      refute command.ready_for_repository_resolution?
      assert_equal ["project_name"], command.missing_context_slots
    end

    test "validates guided_alignment type when provided" do
      command = Command.new(
        project_name: "InventoryService",
        directory_name: "inventory-service",
        repository_input: "inventory-service",
        guided_alignment: "yes"
      )

      assert_not command.valid?
      assert_equal "must be boolean when provided", command.errors[:guided_alignment]
    end

    test "defaults directory name from project name when missing" do
      command = Command.new(
        project_name: "Notes CLI",
        repository_input: "",
        guided_alignment: true
      )

      assert_equal "notes-cli", command.directory_name
      assert_equal "Notes CLI", command.project_name
    end
  end
end
