# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/command_query_handler_registry"

class CommandQueryHandlerRegistryTest < Minitest::Test
  Envelope = Struct.new(:name, :payload, :execution_context, :request_id, keyword_init: true)

  def test_dispatch_calls_registered_handler_with_typed_context
    registry = Redwright::CommandQueryHandlerRegistry.new
    captured = {}

    registry.register("MoveTicket") do |payload:, context:, request_id:|
      captured[:payload] = payload
      captured[:runtime] = context.runtime
      captured[:role] = context.role
      captured[:actor_id] = context.actor_id
      captured[:request_id] = request_id
      { "status" => "ok" }
    end

    result = registry.dispatch(
      Envelope.new(
        name: "MoveTicket",
        payload: { "ticket_id" => "RW-1" },
        execution_context: { "runtime" => "factory", "role" => "coder", "actor_id" => "agent_coder" },
        request_id: "req-7"
      )
    )

    assert_equal(true, result.ok)
    assert_equal({ "status" => "ok" }, result.response)
    assert_equal({ "ticket_id" => "RW-1" }, captured[:payload])
    assert_equal("factory", captured[:runtime])
    assert_equal("coder", captured[:role])
    assert_equal("agent_coder", captured[:actor_id])
    assert_equal("req-7", captured[:request_id])
  end

  def test_dispatch_returns_unsupported_action_when_missing_handler
    registry = Redwright::CommandQueryHandlerRegistry.new

    result = registry.dispatch(
      Envelope.new(
        name: "GetBoard",
        payload: {},
        execution_context: { "runtime" => "interactive", "role" => "human_operator", "actor_id" => "user_1" },
        request_id: "req-8"
      )
    )

    assert_equal(false, result.ok)
    assert_equal("unsupported_action", result.error_code)
  end

  def test_dispatch_returns_execution_failed_on_handler_exception
    registry = Redwright::CommandQueryHandlerRegistry.new
    registry.register("MoveTicket") { raise "boom" }

    result = registry.dispatch(
      Envelope.new(
        name: "MoveTicket",
        payload: {},
        execution_context: { "runtime" => "factory", "role" => "coder", "actor_id" => "agent_coder" },
        request_id: "req-9"
      )
    )

    assert_equal(false, result.ok)
    assert_equal("execution_failed", result.error_code)
    assert_includes(result.error_message, "boom")
  end
end
