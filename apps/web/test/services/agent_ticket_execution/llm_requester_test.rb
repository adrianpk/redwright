require "test_helper"
require Rails.root.join("..", "..", "lib", "redwright", "llm", "request_engine").expand_path.to_s

module AgentTicketExecution
  class LlmRequesterTest < ActiveSupport::TestCase
    test "calls request engine with ticket execution action and records trace" do
      with_agent_ticket_execution_workspace do |fixture|
        write_protocol_files(project: fixture.project, documents: [{path: "AGENTS.md", body: "Read these project files."}])
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
        assert_equal "implementation_default", engine.calls.first.fetch(:context_policy)
        assert_equal true, engine.calls.first.fetch(:dynamic_context_policy)
        assert_equal LlmContract.output_contract, engine.calls.first.fetch(:output_contract)
        assert_equal execution_context.context_sections, engine.calls.first.fetch(:context_sections)
        provider_prompt = JSON.parse(engine.calls.first.fetch(:user_text))
        assert_equal fixture.ticket.id, provider_prompt.dig("request", "ticket_id")
        assert_includes provider_prompt.fetch("context_sections").map { |section| section.fetch("name") }, "repository_tree"
        assert_includes provider_prompt.fetch("context_sections").to_s, "main.go"
        protocol_files = provider_prompt.fetch("context_sections").select { |section| section.fetch("name") == "protocol_files" }
        assert_equal 1, protocol_files.size
        assert_equal "Read these project files.", protocol_files.first.fetch("content").first.fetch("content")
        assert_equal LlmContract::ACTION, recorder.requests.first.fetch(:action)
        assert_equal "implementation_default", recorder.requests.first.fetch(:policy_decision).fetch(:policy_name)
        assert_includes recorder.requests.first.fetch(:user_text), "context_sections"
        assert_equal LlmContract::ACTION, recorder.responses.first.fetch(:action)
        assert_equal fixture.ticket.id, recorder.requests.first.fetch(:ticket_id)
        assert_equal "test", recorder.requests.first.fetch(:source_channel)
        assert_equal "agent-test", recorder.requests.first.fetch(:actor_identifier)
        assert_equal [], recorder.responses.first.fetch(:warnings)
        assert_equal "ok", recorder.responses.first.fetch(:diagnostics).fetch(:contract_validation).fetch(:code)
        assert_equal 123, recorder.responses.first.fetch(:diagnostics).fetch(:context_bytes)
      end
    end

    test "applies context policy through request engine before provider call" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        execution_context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(fixture.ticket),
          workspace: workspace
        )
        client = FakeLlmClient.new(
          "status" => "proposed_changes",
          "summary" => "Add the done command.",
          "files" => [{"path" => "main.go", "operation" => "modify"}],
          "commands" => [{"command" => "go test ./...", "purpose" => "validate"}]
        )
        engine = Redwright::LLM::RequestEngine.new(llm_client: client)
        recorder = FakeTraceRecorder.new

        result = LlmRequester.new(
          request_engine: engine,
          model: "test/model",
          provider: "test",
          trace_recorder: recorder
        ).call(execution_context: execution_context)

        provider_prompt = JSON.parse(client.calls.first.fetch(:user_text))
        provider_section_names = provider_prompt.fetch("context_sections").map { |section| section.fetch("name") }
        response_policy = recorder.responses.first.fetch(:policy_decision)

        assert result.ok?, result.warnings.inspect
        assert_includes provider_section_names, "ticket"
        assert_includes provider_section_names, "project"
        assert_includes provider_section_names, "repository_tree"
        assert_includes provider_section_names, "relevant_files"
        assert_includes provider_section_names, "tests"
        assert_includes provider_section_names, "operational_setup"
        assert_includes provider_section_names, "tree_sitter"
        assert_includes provider_section_names, "protocol_files"
        refute_includes provider_section_names, "quizzes"
        refute_includes provider_section_names, "dumps"
        refute_includes provider_section_names, "llm_based_context"
        assert_equal "implementation_default", response_policy.fetch(:policy_name)
        assert_includes response_policy.fetch(:included_context_sections), "ticket"
        assert_includes response_policy.fetch(:included_context_sections), "repository_tree"
        assert_includes response_policy.fetch(:included_context_sections), "relevant_files"
        assert_includes response_policy.fetch(:included_context_sections), "tests"
        assert_includes response_policy.fetch(:included_context_sections), "operational_setup"
        assert_includes response_policy.fetch(:included_context_sections), "tree_sitter"
        assert_includes response_policy.fetch(:omitted_context_sections), "quizzes"
        refute_includes response_policy.fetch(:omitted_context_sections), "ticket"
        refute_includes response_policy.fetch(:omitted_context_sections), "relevant_files"
        refute_includes response_policy.fetch(:omitted_context_sections), "tests"
        assert_equal "context_layer_not_in_policy:quizzes:implementation_default", response_policy.fetch(:omission_reasons).fetch("quizzes")
      end
    end

    test "returns normalized near-miss contract payload and records diagnostics" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        execution_context = ContextComposer.new.compose(
          ticket: fixture.ticket,
          request: request_payload(fixture.ticket),
          workspace: workspace
        )
        engine = FakeRequestEngine.new(
          "status" => "ready",
          "summary" => "Add the done command.",
          "changes" => [{"type" => "apply_patch", "path" => "main.go", "patch" => "*** Begin Patch\n*** Update File: main.go\n*** End Patch"}],
          "commands" => [{"cmd" => "go test ./...", "purpose" => "validate"}]
        )
        recorder = FakeTraceRecorder.new

        result = LlmRequester.new(
          request_engine: engine,
          model: "test/model",
          provider: "test",
          trace_recorder: recorder
        ).call(execution_context: execution_context)

        assert result.ok?, result.warnings.inspect
        assert_equal "proposed_changes", result.payload.fetch("status")
        assert_equal [{"path" => "main.go", "patch" => "*** Begin Patch\n*** Update File: main.go\n*** End Patch"}], result.payload.fetch("files")
        assert_equal [{"command" => "go test ./...", "purpose" => "validate"}], result.payload.fetch("commands")
        diagnostics = recorder.responses.first.fetch(:diagnostics)
        assert_equal true, diagnostics.fetch(:contract_validation).fetch(:ok)
        assert_includes diagnostics.fetch(:contract_normalizations), {"field" => "status", "from" => "ready", "to" => "proposed_changes"}
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

    class FakeLlmClient
      Completion = Struct.new(:content, :finish_reason, keyword_init: true)

      attr_reader :calls

      def initialize(payload)
        @payload = payload
        @calls = []
      end

      def configured?
        true
      end

      def complete_json(model:, system_prompt:, user_text:)
        calls << {model: model, system_prompt: system_prompt, user_text: user_text}
        Completion.new(content: JSON.generate(@payload), finish_reason: "stop")
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
