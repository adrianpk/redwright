# frozen_string_literal: true

require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/llm/request_engine"
require "redwright/llm/context_section"

class LlmRequestEngineTest < Minitest::Test
  Completion = Struct.new(:content, :finish_reason, keyword_init: true)

  class FakeClient
    attr_reader :calls

    def initialize(content:, configured: true, raises: nil)
      @content = content
      @configured = configured
      @raises = raises
      @calls = []
    end

    def configured?
      @configured
    end

    def complete_json(model:, system_prompt:, user_text:)
      raise @raises if @raises

      @calls << {model: model, system_prompt: system_prompt, user_text: user_text}
      Completion.new(content: @content, finish_reason: "stop")
    end
  end

  def test_generate_structured_message_returns_normalized_success_response
    client = FakeClient.new(content: JSON.generate({"message" => "What type of project is this?", "kind" => "setup_prompt"}))
    engine = Redwright::LLM::RequestEngine.new(llm_client: client)

    response = engine.generate_structured_message(
      model: "openrouter/auto",
      model_role: "non_coding",
      provider: "openrouter",
      action: "project_setup_prompt_render",
      system_prompt: "Return JSON.",
      user_text: JSON.generate({"summary" => "Project setup started."}),
      output_contract: {"required_fields" => ["message"], "rendered_text_field" => "message"},
      context_sections: ["setup_summary", "next_prompt_intent"],
      trace_metadata: {trace_id: "trc-test"}
    )

    assert_predicate response, :ok?
    assert_equal "ok", response.status
    assert_equal "What type of project is this?", response.rendered_text
    assert_equal "setup_prompt", response.semantic_payload.fetch("kind")
    assert_equal "openrouter", response.provider_metadata.fetch(:provider)
    assert_equal "non_coding", response.provider_metadata.fetch(:model_role)
    assert_equal ["setup_summary", "next_prompt_intent"], response.diagnostics.fetch(:context_sections)
    assert_equal "openrouter/auto", client.calls.first.fetch(:model)
  end

  def test_generate_structured_message_reports_context_authority_and_size
    client = FakeClient.new(content: JSON.generate({"message" => "Question?"}))
    engine = Redwright::LLM::RequestEngine.new(llm_client: client)

    response = engine.generate_structured_message(
      model: "openrouter/auto",
      model_role: "non_coding",
      provider: "openrouter",
      action: "project_setup_prompt_render",
      system_prompt: "Return JSON.",
      user_text: "{}",
      context_sections: [
        Redwright::LLM::ContextSection.new(name: "setup_summary", content: "Started", authority: "request_context"),
        Redwright::LLM::ContextSection.new(name: "user_text", content: "hello", authority: "current_user_request")
      ]
    )

    assert_equal ["setup_summary", "user_text"], response.diagnostics.fetch(:context_sections)
    assert_equal "request_context", response.diagnostics.fetch(:context_section_authorities).fetch("setup_summary")
    assert_equal "current_user_request", response.diagnostics.fetch(:context_section_authorities).fetch("user_text")
    assert_operator response.diagnostics.fetch(:context_bytes), :>, 0
  end

  def test_generate_structured_message_redacts_obvious_secrets_before_provider_call
    client = FakeClient.new(content: JSON.generate({"message" => "Question?"}))
    engine = Redwright::LLM::RequestEngine.new(llm_client: client)

    response = engine.generate_structured_message(
      model: "openrouter/auto",
      model_role: "non_coding",
      provider: "openrouter",
      action: "project_setup_prompt_render",
      system_prompt: "Authorization: Bearer abc123",
      user_text: JSON.generate({"user_text" => "api_key=sk-secret password=hunter2"})
    )

    refute_includes client.calls.first.fetch(:system_prompt), "abc123"
    refute_includes client.calls.first.fetch(:user_text), "sk-secret"
    refute_includes client.calls.first.fetch(:user_text), "hunter2"
    assert_equal true, response.diagnostics.fetch(:redacted)
  end

  def test_generate_structured_message_normalizes_invalid_json
    client = FakeClient.new(content: "not json")
    engine = Redwright::LLM::RequestEngine.new(llm_client: client)

    response = engine.generate_structured_message(
      model: "example/model",
      model_role: "non_coding",
      provider: "example",
      action: "project_setup_prompt_render",
      system_prompt: "Return JSON.",
      user_text: "{}"
    )

    assert_equal "invalid_response", response.status
    assert_equal "", response.rendered_text
    assert_equal "not json", response.raw_response_ref
    assert_includes response.warnings, "Provider response was not valid JSON"
    assert_equal "JSON::ParserError", response.diagnostics.fetch(:error_class)
    assert_equal "invalid_json", response.diagnostics.fetch(:response_failure)
  end

  def test_generate_structured_message_normalizes_empty_provider_response
    client = FakeClient.new(content: "")
    engine = Redwright::LLM::RequestEngine.new(llm_client: client)

    response = engine.generate_structured_message(
      model: "example/model",
      model_role: "non_coding",
      provider: "example",
      action: "project_setup_prompt_render",
      system_prompt: "Return JSON.",
      user_text: "{}"
    )

    assert_equal "invalid_response", response.status
    assert_equal "", response.rendered_text
    assert_includes response.warnings, "Provider response was empty"
    assert_equal "empty_content", response.diagnostics.fetch(:response_failure)
  end

  def test_generate_structured_message_normalizes_non_object_json
    client = FakeClient.new(content: JSON.generate(["wrong"]))
    engine = Redwright::LLM::RequestEngine.new(llm_client: client)

    response = engine.generate_structured_message(
      model: "example/model",
      model_role: "non_coding",
      provider: "example",
      action: "project_setup_prompt_render",
      system_prompt: "Return JSON.",
      user_text: "{}"
    )

    assert_equal "invalid_response", response.status
    assert_equal "[\"wrong\"]", response.raw_response_ref
    assert_includes response.warnings, "Provider response did not match the output contract"
    assert_equal "non_object_json", response.diagnostics.fetch(:response_failure)
    assert_equal "Array", response.diagnostics.fetch(:parsed_class)
  end

  def test_generate_structured_message_normalizes_missing_required_field
    client = FakeClient.new(content: JSON.generate({"text" => "Wrong field"}))
    engine = Redwright::LLM::RequestEngine.new(llm_client: client)

    response = engine.generate_structured_message(
      model: "example/model",
      model_role: "non_coding",
      provider: "example",
      action: "project_setup_prompt_render",
      system_prompt: "Return JSON.",
      user_text: "{}",
      output_contract: {"required_fields" => ["message"], "rendered_text_field" => "message"}
    )

    assert_equal "invalid_response", response.status
    assert_equal "", response.rendered_text
    assert_equal "{\"text\":\"Wrong field\"}", response.raw_response_ref
    assert_includes response.warnings, "Provider response missed required fields: message"
    assert_equal "missing_required_fields", response.diagnostics.fetch(:response_failure)
    assert_equal ["message"], response.diagnostics.fetch(:missing_required_fields)
  end

  def test_generate_structured_message_normalizes_provider_error_without_raising
    client = FakeClient.new(content: "{}", raises: RuntimeError.new("provider exploded"))
    engine = Redwright::LLM::RequestEngine.new(llm_client: client)

    response = engine.generate_structured_message(
      model: "example/model",
      model_role: "non_coding",
      provider: "example",
      action: "project_setup_prompt_render",
      system_prompt: "Return JSON.",
      user_text: "{}"
    )

    assert_equal "provider_error", response.status
    assert_equal "", response.rendered_text
    assert_includes response.warnings, "Provider request failed"
    assert_equal "RuntimeError", response.diagnostics.fetch(:error_class)
    assert_equal "provider exploded", response.diagnostics.fetch(:error_message)
  end

  def test_generate_structured_message_normalizes_unconfigured_client
    client = FakeClient.new(content: "{}", configured: false)
    engine = Redwright::LLM::RequestEngine.new(llm_client: client)

    response = engine.generate_structured_message(
      model: "example/model",
      model_role: "non_coding",
      provider: "example",
      action: "project_setup_prompt_render",
      system_prompt: "Return JSON.",
      user_text: "{}"
    )

    assert_equal "llm_unavailable", response.status
    assert_equal [], client.calls
    assert_includes response.warnings, "LLM client is not configured"
  end
end
