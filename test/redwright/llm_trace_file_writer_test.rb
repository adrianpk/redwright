# frozen_string_literal: true

require "json"
require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/app_config"
require "redwright/llm_trace_file_writer"

class LlmTraceFileWriterTest < Minitest::Test
  def test_writes_ndjson_event
    Dir.mktmpdir("redwright-llm-trace-writer-") do |dir|
      path = File.join(dir, "llm.ndjson")
      writer = Redwright::LlmTraceFileWriter.new(
        config: trace_config(path: path, include_payloads: true)
      )

      writer.write(event: "llm_request", llm_call_id: "llm-1", payload_bytes: 12, user_text: "hello")

      lines = File.readlines(path, chomp: true)
      assert_equal(1, lines.size)
      parsed = JSON.parse(lines.first)
      assert_equal("llm_request", parsed.fetch("event"))
      assert_equal("llm-1", parsed.fetch("llm_call_id"))
      assert_equal("hello", parsed.fetch("user_text"))
      assert(parsed.key?("timestamp"))
    end
  end

  def test_redacts_secret_env_values_and_bearer_tokens
    Dir.mktmpdir("redwright-llm-trace-redact-") do |dir|
      path = File.join(dir, "llm.ndjson")
      writer = Redwright::LlmTraceFileWriter.new(
        config: trace_config(path: path, include_payloads: true),
        env: {"OPENAI_API_KEY" => "sk-secret-123"}
      )

      writer.write(
        event: "llm_response",
        llm_call_id: "llm-2",
        raw_output: 'Authorization: Bearer abc123 and secret sk-secret-123'
      )

      parsed = JSON.parse(File.read(path).lines.first)
      assert_equal("Authorization: Bearer [REDACTED] and secret [REDACTED]", parsed.fetch("raw_output"))
    end
  end

  def test_rotates_when_max_bytes_is_exceeded
    Dir.mktmpdir("redwright-llm-trace-rotate-") do |dir|
      path = File.join(dir, "llm.ndjson")
      writer = Redwright::LlmTraceFileWriter.new(
        config: trace_config(path: path, max_bytes: 80, keep_files: 2, include_payloads: true)
      )

      writer.write(event: "llm_request", llm_call_id: "llm-1", user_text: "x" * 120)
      writer.write(event: "llm_request", llm_call_id: "llm-2", user_text: "y" * 120)

      assert(File.exist?(path))
      assert(File.exist?("#{path}.1"))
    end
  end

  private

  def trace_config(path:, max_bytes: 10_485_760, keep_files: 5, include_payloads: false)
    Redwright::LlmFileTraceConfig.new(
      enabled: true,
      path: path,
      max_bytes: max_bytes,
      keep_files: keep_files,
      include_payloads: include_payloads,
      include_system_prompt: true,
      include_user_text: true,
      include_raw_output: true
    )
  end
end
