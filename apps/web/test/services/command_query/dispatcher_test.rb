require "test_helper"

module CommandQuery
  class DispatcherTest < ActiveSupport::TestCase
    test "dispatches registered command handlers" do
      dispatcher = Dispatcher.new
      dispatcher.register_command("CreateTicket") do |payload:, context:, request_id:|
        {
          "title" => payload.fetch("title"),
          "actor_id" => context.fetch("actor_id"),
          "request_id" => request_id
        }
      end

      result = dispatcher.call(
        "kind" => "command",
        "name" => "CreateTicket",
        "payload" => {"title" => "Add command API"},
        "execution_context" => {"actor_id" => "agent-coder"},
        "request_id" => "req-command"
      )

      assert result.ok?, result.to_h.inspect
      assert_equal "Add command API", result.data.fetch("title")
      assert_equal "agent-coder", result.data.fetch("actor_id")
      assert_equal "req-command", result.data.fetch("request_id")
    end

    test "dispatches registered query handlers" do
      dispatcher = Dispatcher.new
      dispatcher.register_query("GetBoard") do |payload:, context:, request_id:|
        Result.ok(
          request_id: request_id,
          data: {
            "project_id" => payload.fetch("project_id"),
            "actor_id" => context.fetch("actor_id")
          }
        )
      end

      result = dispatcher.call(
        Envelope.new(
          kind: "query",
          name: "GetBoard",
          payload: {"project_id" => 3},
          execution_context: {"actor_id" => "human"},
          request_id: "req-query"
        )
      )

      assert result.ok?, result.to_h.inspect
      assert_equal({"project_id" => 3, "actor_id" => "human"}, result.data)
    end

    test "returns structured invalid envelope errors" do
      result = Dispatcher.new.call(
        "kind" => "command",
        "name" => "CreateTicket",
        "payload" => nil,
        "execution_context" => {},
        "request_id" => "req-invalid"
      )

      assert result.error?
      assert_equal "req-invalid", result.request_id
      assert_equal "invalid_envelope", result.errors.first[:code]
      assert_equal ["invalid_payload"], result.errors.first[:details].map { |error| error[:code] }
    end

    test "returns structured unsupported action error" do
      result = Dispatcher.new.call(
        "kind" => "command",
        "name" => "MissingCommand",
        "payload" => {},
        "execution_context" => {"actor_id" => "agent-coder"},
        "request_id" => "req-missing"
      )

      assert result.error?
      assert_equal "req-missing", result.request_id
      assert_equal "unsupported_action", result.errors.first[:code]
      assert_match "MissingCommand", result.errors.first[:message]
    end

    test "returns execution failure errors from handlers" do
      dispatcher = Dispatcher.new
      dispatcher.register_command("Explode") do |**_kwargs|
        raise "boom"
      end

      result = dispatcher.call(
        "kind" => "command",
        "name" => "Explode",
        "payload" => {},
        "execution_context" => {"actor_id" => "agent-coder"},
        "request_id" => "req-boom"
      )

      assert result.error?
      assert_equal "req-boom", result.request_id
      assert_equal "execution_failed", result.errors.first[:code]
      assert_equal "boom", result.errors.first[:message]
    end
  end
end
