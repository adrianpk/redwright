require "test_helper"

module AgentTicketExecution
  class LlmContractTest < ActiveSupport::TestCase
    test "accepts proposed change response shape" do
      result = LlmContract.new.validate(
        "status" => "proposed_changes",
        "summary" => "Add the done command.",
        "files" => [{"path" => "main.go", "operation" => "modify"}],
        "commands" => [{"command" => "go test ./...", "purpose" => "validate"}],
        "actions" => [{"type" => "apply_patch", "target" => "main.go"}],
        "validation_expectations" => ["go test ./... passes"],
        "warnings" => []
      )

      assert result.ok?
      assert_equal "proposed_changes", result.payload.fetch("status")
      assert_equal ["go test ./... passes"], result.payload.fetch("validation_expectations")
    end

    test "accepts corrective retry response shape" do
      result = LlmContract.new.validate(
        "status" => "needs_correction",
        "summary" => "Fix invalid index handling.",
        "retry_instruction" => "Add bounds checks before indexing tasks.",
        "files" => [{"path" => "main.go", "operation" => "modify"}],
        "warnings" => ["previous patch missed task 0"]
      )

      assert result.ok?
      assert_equal "needs_correction", result.payload.fetch("status")
      assert_equal "Add bounds checks before indexing tasks.", result.payload.fetch("retry_instruction")
    end

    test "normalizes useful near-miss executable response shape" do
      result = LlmContract.new.validate(
        "status" => "ready",
        "summary" => "Add done command.",
        "changes" => [
          {
            "type" => "apply_patch",
            "path" => "main.go",
            "patch" => "*** Begin Patch\n*** Update File: main.go\n*** End Patch"
          }
        ],
        "commands" => [
          {"cmd" => "go test ./...", "purpose" => "validate"}
        ]
      )

      assert result.ok?, result.message
      assert_equal "proposed_changes", result.payload.fetch("status")
      assert_equal(
        [{"path" => "main.go", "patch" => "*** Begin Patch\n*** Update File: main.go\n*** End Patch"}],
        result.payload.fetch("files")
      )
      assert_equal [{"command" => "go test ./...", "purpose" => "validate"}], result.payload.fetch("commands")
      assert_equal 4, result.normalizations.length
      assert_includes result.normalizations, {"field" => "status", "from" => "ready", "to" => "proposed_changes"}
      assert_includes result.normalizations, {"field" => "changes", "to" => "files"}
      assert_includes result.normalizations, {"field" => "changes[0].type", "action" => "dropped"}
      assert_includes result.normalizations, {"field" => "commands[0].cmd", "to" => "commands[0].command"}
    end

    test "accepts blocked response only with blocking reason" do
      blocked = LlmContract.new.validate(
        "status" => "blocked",
        "summary" => "Cannot continue.",
        "blocking_reason" => "The repository has no writable workspace."
      )
      missing_reason = LlmContract.new.validate(
        "status" => "blocked",
        "summary" => "Cannot continue."
      )

      assert blocked.ok?
      assert_not missing_reason.ok?
      assert_equal "missing_blocking_reason", missing_reason.code
    end

    test "rejects malformed array fields" do
      result = LlmContract.new.validate(
        "status" => "proposed_changes",
        "summary" => "Add implementation.",
        "commands" => "go test ./..."
      )

      assert_not result.ok?
      assert_equal "invalid_commands", result.code
    end
  end
end
