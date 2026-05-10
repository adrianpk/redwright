require "test_helper"

module DumpLoops
  class CurationProviderTest < ActiveSupport::TestCase
    test "polishes entry from valid llm output" do
      engine = CapturingRequestEngine.new([self.class.entry_response])
      provider = CurationProvider.new(request_engine: engine, model: "test/model", provider: "test")

      result = provider.polish_entry(input: {"raw_input" => "teh dump", "dump" => {"title" => "Notes"}})

      assert result.usable?
      assert_equal "The dump.", result.attributes.fetch("polished_input")
      assert_equal ["dump-context"], result.attributes.fetch("tag_suggestions")
      assert_equal ["dump_entry_polish"], engine.actions
      assert_equal "polished_input", engine.output_contracts.first.fetch("rendered_text_field")
    end

    test "curates dump from valid llm output" do
      engine = CapturingRequestEngine.new([self.class.curated_response])
      provider = CurationProvider.new(request_engine: engine, model: "test/model", provider: "test")

      result = provider.curate_dump(input: {"dump" => {"title" => "Conversation"}, "entries" => [{"polished_input" => "Dump context."}]})

      assert result.usable?
      assert_equal "Conversation Capture", result.attributes.fetch("central_topic")
      assert_equal "Dump captures user-led context.", result.attributes.fetch("summary")
      assert_equal ["conversation"], result.attributes.fetch("tag_suggestions")
      assert_equal ["dump_curation"], engine.actions
    end

    test "returns deterministic redacted entry fallback without llm" do
      result = CurationProvider.new.polish_entry(input: {"raw_input" => "Use API_TOKEN=abc123"})

      assert_not result.usable?
      assert_equal "llm_unavailable", result.fallback_reason
      assert_equal "Use API_TOKEN=[REDACTED]", result.attributes.fetch("polished_input")
      assert_includes result.attributes.fetch("warnings"), "llm_unavailable"
    end

    test "returns deterministic curated fallback for malformed llm output" do
      engine = CapturingRequestEngine.new([self.class.malformed_response])
      provider = CurationProvider.new(request_engine: engine, model: "test/model", provider: "test")

      result = provider.curate_dump(
        input: {
          "dump" => {"title" => "Dump Notes"},
          "entries" => [{"polished_input" => "The first useful note."}]
        }
      )

      assert_not result.usable?
      assert_equal "llm_malformed", result.fallback_reason
      assert_equal "Dump Notes", result.attributes.fetch("central_topic")
      assert_equal "The first useful note.", result.attributes.fetch("summary")
      assert_includes result.errors, "unexpected field: rationale"
    end

    class CapturingRequestEngine
      attr_reader :actions, :output_contracts

      def initialize(responses)
        @responses = responses
        @actions = []
        @output_contracts = []
      end

      def generate_structured_message(action:, output_contract:, **)
        actions << action
        output_contracts << output_contract
        responses.shift
      end

      private

      attr_reader :responses
    end

    TestResponse = Struct.new(:status, :semantic_payload, :warnings, keyword_init: true) do
      def ok?
        status == "ok"
      end
    end

    class << self
      def entry_response
        TestResponse.new(
          status: "ok",
          semantic_payload: {
            "polished_input" => "The dump.",
            "topic_heading" => "Dump",
            "derived_thread_hints" => [],
            "tag_suggestions" => ["Dump Context"],
            "warnings" => []
          },
          warnings: []
        )
      end

      def curated_response
        TestResponse.new(
          status: "ok",
          semantic_payload: {
            "central_topic" => "Conversation Capture",
            "summary" => "Dump captures user-led context.",
            "key_concepts" => ["Dump"],
            "decisions_or_preferences" => ["Use Conversation."],
            "tensions_and_tradeoffs" => [],
            "assumptions" => [],
            "derived_threads" => [],
            "possible_downstream_artifacts" => [],
            "open_questions" => [],
            "tag_suggestions" => ["Conversation"]
          },
          warnings: []
        )
      end

      def malformed_response
        TestResponse.new(
          status: "ok",
          semantic_payload: {
            "central_topic" => "Dump",
            "summary" => "Summary",
            "key_concepts" => [],
            "decisions_or_preferences" => [],
            "tensions_and_tradeoffs" => [],
            "assumptions" => [],
            "derived_threads" => [],
            "possible_downstream_artifacts" => [],
            "open_questions" => [],
            "tag_suggestions" => [],
            "rationale" => "Hidden reasoning"
          },
          warnings: []
        )
      end
    end
  end
end
