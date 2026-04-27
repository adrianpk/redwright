# frozen_string_literal: true

require "stringio"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/trace"

class TraceTest < Minitest::Test
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
end
