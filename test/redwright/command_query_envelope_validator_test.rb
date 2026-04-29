# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/command_query_envelope_validator"

class CommandQueryEnvelopeValidatorTest < Minitest::Test
  def test_accepts_valid_command_envelope
    validator = Redwright::CommandQueryEnvelopeValidator.new

    result = validator.validate(
      {
        "kind" => "command",
        "name" => "MoveTicket",
        "payload" => { "ticket_id" => "RW-42", "to_column" => "review" },
        "execution_context" => {
          "runtime" => "factory",
          "role" => "coder",
          "actor_id" => "agent_coder"
        },
        "request_id" => "req-1"
      }
    )

    assert_equal(true, result.valid)
    assert_equal("command", result.kind)
    assert_equal("MoveTicket", result.name)
    assert_empty(result.errors)
  end

  def test_accepts_valid_query_envelope
    validator = Redwright::CommandQueryEnvelopeValidator.new

    result = validator.validate(
      {
        "kind" => "query",
        "name" => "GetBoard",
        "payload" => { "project_id" => "p1" },
        "execution_context" => {
          "runtime" => "interactive",
          "role" => "human_operator",
          "actor_id" => "user_1"
        },
        "request_id" => "req-2"
      }
    )

    assert_equal(true, result.valid)
    assert_equal("query", result.kind)
    assert_equal("GetBoard", result.name)
    assert_empty(result.errors)
  end

  def test_rejects_invalid_envelope_shape
    validator = Redwright::CommandQueryEnvelopeValidator.new

    result = validator.validate([])

    assert_equal(false, result.valid)
    assert_includes(result.errors, "invalid_envelope:type_mismatch")
  end

  def test_rejects_unknown_command
    validator = Redwright::CommandQueryEnvelopeValidator.new

    result = validator.validate(
      {
        "kind" => "command",
        "name" => "DeleteUniverse",
        "payload" => {},
        "execution_context" => {
          "runtime" => "factory",
          "role" => "coder",
          "actor_id" => "agent_coder"
        },
        "request_id" => "req-3"
      }
    )

    assert_equal(false, result.valid)
    assert_includes(result.errors, "unsupported_action:command:DeleteUniverse")
  end

  def test_rejects_invalid_execution_context
    validator = Redwright::CommandQueryEnvelopeValidator.new

    result = validator.validate(
      {
        "kind" => "query",
        "name" => "GetTickets",
        "payload" => {},
        "execution_context" => {
          "runtime" => "anywhere",
          "role" => "guest",
          "actor_id" => ""
        },
        "request_id" => "req-4"
      }
    )

    assert_equal(false, result.valid)
    assert_includes(result.errors, "invalid_envelope:execution_context:runtime")
    assert_includes(result.errors, "invalid_envelope:execution_context:role")
    assert_includes(result.errors, "invalid_envelope:execution_context:actor_id")
  end
end
