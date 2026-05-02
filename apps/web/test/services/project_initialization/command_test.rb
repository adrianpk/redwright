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

    test "requires project_name directory_name and repository_input" do
      command = Command.new(project_name: "", directory_name: "", repository_input: "")

      assert_not command.valid?
      assert_equal "can't be blank", command.errors[:project_name]
      assert_equal "can't be blank", command.errors[:directory_name]
      assert_equal "can't be blank", command.errors[:repository_input]
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
  end
end
