require "test_helper"

module AgentTicketExecution
  class LlmRequesterTest < ActiveSupport::TestCase
    test "calls request engine with ticket execution action and records trace" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        execution_context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(fixture.ticket),
          workspace: workspace
        )
        engine = FakeRequestEngine.new(
          "status" => "proposed_changes",
          "summary" => "Add the done command.",
          "files" => [{"path" => "main.go", "operation" => "modify"}],
          "commands" => [{"command" => "go test ./...", "purpose" => "validate"}]
        )
        recorder = FakeTraceRecorder.new

        result = LlmRequester.new(
          request_engine: engine,
          model: "test/model",
          provider: "test",
          trace_recorder: recorder
        ).call(execution_context: execution_context)

        assert result.ok?, result.warnings.inspect
        assert_equal LlmContract::ACTION, engine.calls.first.fetch(:action)
        assert_equal LlmContract.output_contract, engine.calls.first.fetch(:output_contract)
        assert_equal execution_context.context_sections, engine.calls.first.fetch(:context_sections)
        provider_prompt = JSON.parse(engine.calls.first.fetch(:user_text))
        assert_equal fixture.ticket.id, provider_prompt.dig("request", "ticket_id")
        assert_includes provider_prompt.fetch("context_sections").map { |section| section.fetch("name") }, "repository_tree"
        assert_includes provider_prompt.fetch("context_sections").to_s, "main.go"
        protocol_model_section = provider_prompt.fetch("context_sections").find { |section| section.fetch("name") == "protocol_model" }
        assert_equal true, protocol_model_section.fetch("content_omitted")
        assert_equal "duplicated_by_protocol_files", protocol_model_section.fetch("omission_reason")
        refute_includes protocol_model_section.keys, "content"
        assert_equal LlmContract::ACTION, recorder.requests.first.fetch(:action)
        assert_includes recorder.requests.first.fetch(:user_text), "context_sections"
        assert_equal LlmContract::ACTION, recorder.responses.first.fetch(:action)
        assert_equal fixture.ticket.id, recorder.requests.first.fetch(:ticket_id)
        assert_equal "test", recorder.requests.first.fetch(:source_channel)
        assert_equal "agent-test", recorder.requests.first.fetch(:actor_identifier)
        assert_equal [], recorder.responses.first.fetch(:warnings)
        assert_equal({context_bytes: 123}, recorder.responses.first.fetch(:diagnostics))
      end
    end

    test "returns failed result when response misses ticket execution contract" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        execution_context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(fixture.ticket),
          workspace: workspace
        )
        engine = FakeRequestEngine.new(
          "status" => "blocked",
          "summary" => "Cannot continue."
        )

        result = LlmRequester.new(
          request_engine: engine,
          model: "test/model",
          provider: "test"
        ).call(execution_context: execution_context)

        assert_not result.ok?
        assert_includes result.warnings, "blocking_reason is required when status is blocked"
      end
    end

    private

    def request_payload(ticket)
      {
        "mode" => "targeted",
        "ticket_id" => ticket.id,
        "branch_name" => "agent-ticket-#{ticket.id}",
        "source_channel" => "test",
        "actor_identifier" => "agent-test"
      }
    end

    class FakeRequestEngine
      Response = Struct.new(
        :status,
        :semantic_payload,
        :rendered_text,
        :provider_metadata,
        :warnings,
        :raw_response_ref,
        :diagnostics,
        keyword_init: true
      ) do
        def ok?
          status == "ok"
        end
      end

      attr_reader :calls

      def initialize(payload)
        @payload = payload
        @calls = []
      end

      def generate_structured_message(**kwargs)
        calls << kwargs
        Response.new(
          status: "ok",
          semantic_payload: @payload,
          rendered_text: @payload.fetch("summary", ""),
          provider_metadata: {finish_reason: "stop"},
          warnings: [],
          raw_response_ref: @payload.to_json,
          diagnostics: {context_bytes: 123}
        )
      end
    end

    class FakeTraceRecorder
      attr_reader :requests, :responses

      def initialize
        @requests = []
        @responses = []
      end

      def record_request(**kwargs)
        requests << kwargs
        "llm-call-1"
      end

      def record_response(**kwargs)
        responses << kwargs
      end
    end
  end
end
