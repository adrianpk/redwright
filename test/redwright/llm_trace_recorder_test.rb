# frozen_string_literal: true

require "json"
require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/app_config"
require "redwright/llm/trace_recorder"

class LlmTraceRecorderTest < Minitest::Test
  def teardown
    Redwright::Trace.reset_configuration!
  end

  def test_records_request_and_response_through_existing_trace_boundary
    Dir.mktmpdir("redwright-llm-trace-recorder-") do |dir|
      Redwright::Trace.configure(
        tracing: Redwright::TracingConfig.new(
          llm_file: Redwright::LlmFileTraceConfig.new(
            enabled: true,
            path: File.join(dir, "llm.ndjson"),
            max_bytes: 10_485_760,
            keep_files: 5,
            include_payloads: true,
            include_system_prompt: true,
            include_user_text: true,
            include_raw_output: true
          )
        )
      )
      recorder = Redwright::LLM::TraceRecorder.new

      call_id = recorder.record_request(
        model_role: "non_coding",
        provider: "openrouter",
        model: "openrouter/auto",
        action: "project_setup_prompt_render",
        payload_bytes: 12,
        trace_id: "trc-test",
        project_id: 77,
        session_id: 41,
        source_channel: "project_setup",
        system_prompt: "system",
        user_text: "{}",
        context_sections: ["setup_summary"],
        policy_decision: {
          policy_name: "planning_default",
          included_context_sections: ["setup_summary"],
          omitted_context_sections: []
        }
      )
      recorder.record_response(
        status: "ok",
        latency_ms: 3,
        output_bytes: 18,
        llm_call_id: call_id,
        trace_id: "trc-test",
        parsed_message: "Question?",
        raw_output: "{\"message\":\"Question?\"}",
        action: "project_setup_prompt_render",
        model_role: "non_coding",
        provider: "openrouter",
        model: "openrouter/auto",
        payload_bytes: 12,
        warnings: ["Provider response was empty"],
        diagnostics: {response_failure: "empty_content"},
        policy_decision: {
          policy_name: "planning_default",
          included_context_sections: ["setup_summary"],
          omitted_context_sections: []
        },
        project_id: 77,
        session_id: 41,
        source_channel: "project_setup"
      )

      lines = File.readlines(File.join(dir, "llm.ndjson"), chomp: true)
      request = JSON.parse(lines.fetch(0))
      response = JSON.parse(lines.fetch(1))
      assert_equal call_id, request.fetch("llm_call_id")
      assert_equal call_id, response.fetch("llm_call_id")
      assert_equal "project_setup_prompt_render", request.fetch("action")
      assert_equal "non_coding", request.fetch("model_role")
      assert_equal ["setup_summary"], request.fetch("context_sections")
      assert_equal "planning_default", request.fetch("policy_decision").fetch("policy_name")
      assert_equal "ok", response.fetch("status")
      assert_equal "Question?", response.fetch("parsed_message")
      assert_equal ["Provider response was empty"], response.fetch("warnings")
      assert_equal "empty_content", response.fetch("diagnostics").fetch("response_failure")
      assert_equal "planning_default", response.fetch("policy_decision").fetch("policy_name")
    end
  end

  def test_trace_write_failures_do_not_raise_through_recorder
    Redwright::Trace.configure(
      tracing: Redwright::TracingConfig.new(
        llm_file: Redwright::LlmFileTraceConfig.new(
          enabled: true,
          path: "/dev/null/llm.ndjson",
          max_bytes: 10_485_760,
          keep_files: 5,
          include_payloads: false,
          include_system_prompt: false,
          include_user_text: false,
          include_raw_output: false
        )
      )
    )
    recorder = Redwright::LLM::TraceRecorder.new

    call_id = recorder.record_request(
      model_role: "non_coding",
      provider: "openrouter",
      model: "openrouter/auto",
      action: "project_setup_prompt_render",
      payload_bytes: 12
    )

    recorder.record_response(
      status: "fallback",
      latency_ms: 0,
      output_bytes: 0,
      llm_call_id: call_id,
      action: "project_setup_prompt_render",
      model_role: "non_coding",
      provider: "openrouter",
      model: "openrouter/auto",
      payload_bytes: 12
    )
  end
end
