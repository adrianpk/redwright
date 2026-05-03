# frozen_string_literal: true

require "stringio"
require "json"
require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/app_config"
require "redwright/trace"

class TraceTest < Minitest::Test
  def teardown
    Redwright::Trace.reset_configuration!
  end

  def test_llm_trace_can_be_enabled_independently
    out = capture_stdout do
      with_env("REDWRIGHT_TRACE" => "", "REDWRIGHT_TRACE_LLM" => "1", "REDWRIGHT_TRACE_SQLITE" => "") do
        Redwright::Trace.llm_request(role: "non_coding", provider: "openai", model: "gpt-5-mini", action: "intent", payload_bytes: 1)
        Redwright::Trace.sqlite(op: "insert", table: "tasks")
      end
    end

    assert_includes(out, "LLM REQUEST")
    refute_includes(out, "SQLITE TRACE")
  end

  def test_global_trace_enables_all_classes
    out = capture_stdout do
      with_env("REDWRIGHT_TRACE" => "1", "REDWRIGHT_TRACE_LLM" => "", "REDWRIGHT_TRACE_SQLITE" => "", "REDWRIGHT_TRACE_RUNTIME" => "") do
        Redwright::Trace.llm_request(role: "non_coding", provider: "openai", model: "gpt-5-mini", action: "intent", payload_bytes: 1)
        Redwright::Trace.sqlite(op: "insert", table: "tasks")
        Redwright::Trace.runtime(trace_id: "trc-1")
      end
    end

    assert_includes(out, "LLM REQUEST")
    assert_includes(out, "SQLITE TRACE")
    assert_includes(out, "RUNTIME TRACE")
  end

  def test_llm_file_trace_writes_correlated_request_and_response_events_without_stdout_trace_flag
    Dir.mktmpdir("redwright-trace-file-") do |dir|
      path = File.join(dir, "llm.ndjson")
      Redwright::Trace.configure(
        tracing: Redwright::TracingConfig.new(
          llm_file: Redwright::LlmFileTraceConfig.new(
            enabled: true,
            path: path,
            max_bytes: 10_485_760,
            keep_files: 5,
            include_payloads: true,
            include_system_prompt: true,
            include_user_text: true,
            include_raw_output: true
          )
        )
      )

      out = capture_stdout do
        call_id = Redwright::Trace.llm_request(
          role: "non_coding",
          provider: "openai",
          model: "gpt-5-mini",
          action: "intent",
          payload_bytes: 11,
          trace_id: "trc-1",
          project_ref: "rw",
          source_channel: "telegram",
          user_text: "hello"
        )
        Redwright::Trace.llm_response(
          llm_call_id: call_id,
          status: "ok",
          latency_ms: 12,
          output_bytes: 20,
          trace_id: "trc-1",
          project_ref: "rw",
          source_channel: "telegram",
          action: "intent",
          role: "non_coding",
          provider: "openai",
          model: "gpt-5-mini",
          payload_bytes: 11,
          raw_output: "{\"ok\":true}"
        )
      end

      assert_equal("", out)
      lines = File.readlines(path, chomp: true)
      assert_equal(2, lines.size)
      request = JSON.parse(lines[0])
      response = JSON.parse(lines[1])
      assert_equal(request.fetch("llm_call_id"), response.fetch("llm_call_id"))
      assert_equal("trc-1", request.fetch("trace_id"))
      assert_equal("rw", request.fetch("project_ref"))
      assert_equal("telegram", request.fetch("source_channel"))
      assert_equal("hello", request.fetch("user_text"))
      assert_equal("{\"ok\":true}", response.fetch("raw_output"))
    end
  end

  def test_llm_file_write_failures_do_not_raise
    Dir.mktmpdir("redwright-trace-file-failure-") do |dir|
      path = File.join(dir, "as-directory")
      Dir.mkdir(path)
      Redwright::Trace.configure(
        tracing: Redwright::TracingConfig.new(
          llm_file: Redwright::LlmFileTraceConfig.new(
            enabled: true,
            path: path,
            max_bytes: 10_485_760,
            keep_files: 5,
            include_payloads: false,
            include_system_prompt: false,
            include_user_text: false,
            include_raw_output: false
          )
        )
      )

      err = capture_stderr do
        Redwright::Trace.llm_request(
          role: "non_coding",
          provider: "openai",
          model: "gpt-5-mini",
          action: "intent",
          payload_bytes: 1
        )
      end

      assert_includes(err, "llm trace file write failed:")
    end
  end

  private

  def capture_stdout
    original = $stdout
    io = StringIO.new
    $stdout = io
    yield
    io.string
  ensure
    $stdout = original
  end

  def with_env(vars)
    backup = {}
    vars.each_key do |key|
      backup[key] = ENV.key?(key) ? ENV[key] : :__missing__
    end
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    backup.each do |key, value|
      if value == :__missing__
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end

  def capture_stderr
    original = $stderr
    io = StringIO.new
    $stderr = io
    yield
    io.string
  ensure
    $stderr = original
  end
end
