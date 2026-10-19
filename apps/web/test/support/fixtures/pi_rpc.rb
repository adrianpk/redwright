require "json"

root = ENV.fetch("FIXTURE_ROOT")
scenario = ENV.fetch("FIXTURE_SCENARIO")
File.open(File.join(root, "pids"), "a") { |file| file.puts(Process.pid) }
raise "inherited unrelated environment" if ENV.key?("UNRELATED_FIXTURE_SECRET")
if ARGV == ["--version"]
  puts(scenario == "wrong-version" ? "1.2.0" : "1.3.0")
  exit
end
expected = %w[--mode rpc --no-session --no-tools --no-extensions --no-mcp --no-skills --no-prompt-templates --no-themes --no-context-files --no-approve --offline]
raise "changed launch flags" unless ARGV.take(expected.size) == expected
raise "wrong provider" unless ARGV[ARGV.index("--provider") + 1] == "fixture-provider"
raise "wrong model" unless ARGV[ARGV.index("--model") + 1] == "fixture-model"
raise "prompt on argv" if ARGV.any? { |arg| arg.include?("source material") }
File.write(File.join(root, "rpc-started"), "yes")
STDOUT.sync = true
STDERR.sync = true

send_record = lambda do |record|
  bytes = JSON.generate(record) + (scenario == "crlf" ? "\r\n" : "\n")
  if scenario == "split"
    bytes.bytes.each_slice(7) { |slice| STDOUT.write(slice.pack("C*")) }
  else
    STDOUT.write(bytes)
  end
end

model = {"id" => "fixture-model", "provider" => "fixture-provider"}
thinking = "off"
compaction = true
prompted = false

STDIN.each_line do |line|
  request = JSON.parse(line)
  type = request.fetch("type")
  data = nil
  data = {"cancelled" => false} if type == "new_session"
  compaction = request.fetch("enabled") if type == "set_auto_compaction"
  if type == "set_model"
    raise "model request changed" unless request.values_at("provider", "modelId") == ["fixture-provider", "fixture-model"]
    data = scenario == "wrong-model" ? model.merge("id" => "other") : model
  end
  data = {"levels" => %w[off low high]} if type == "get_available_thinking_levels"
  thinking = request.fetch("level") if type == "set_thinking_level"
  if type == "get_state"
    data = {"model" => model, "thinkingLevel" => thinking, "isStreaming" => false, "isCompacting" => false,
      "pendingMessageCount" => 0, "autoCompactionEnabled" => compaction}
  end
  if type == "prompt"
    raise "missing host context" unless request.fetch("message").include?("source material") && request.fetch("message").include?("Output JSON Schema:")
    prompted = true
    File.write(File.join(root, "prompted"), "yes")
    data = {"disposition" => %w[handled queued].include?(scenario) ? scenario : "started"}
  end
  response = {"id" => request.fetch("id"), "type" => "response", "command" => type, "success" => true}
  response["data"] = data unless data.nil?
  response["id"] = "unrelated" if scenario == "wrong-id"
  if scenario == "rejected" && type == "set_model"
    response.merge!("success" => false, "error" => "private fixture provider detail")
  end
  send_record.call({"type" => "session_info_changed", "name" => "fixture"}) if scenario == "interleaved"
  send_record.call(response)
  next unless type == "prompt" && data["disposition"] == "started"
  next if scenario == "ack-only"
  if scenario == "invalid-utf8"
    STDOUT.write("\xff\n".b)
    next
  end
  if scenario == "malformed"
    STDOUT.write("{invalid}\n")
    next
  end
  if scenario == "ui"
    send_record.call({"type" => "extension_ui_request", "id" => "ui", "method" => "select"})
    next
  end
  if scenario == "tool"
    send_record.call({"type" => "tool_execution_start", "toolName" => "bash", "args" => {}})
    next
  end
  send_record.call({"type" => "agent_start"})
  send_record.call({"type" => "message_update", "assistantMessageEvent" => {"type" => "text_delta", "delta" => "partial, never final"}})
  text = JSON.generate({"title" => "Bounded output", "body" => "Behavior \u2028 remains \u2029 bounded. ☃"})
  text = "not JSON" if scenario == "invalid-result"
  text = JSON.generate({"title" => "Wrong shape", "body" => 7}) if scenario == "invalid-schema"
  message = {"role" => "assistant", "content" => [{"type" => "text", "text" => text}], "provider" => model["provider"],
    "model" => model["id"], "stopReason" => scenario == "provider-error" ? "error" : "stop",
    "usage" => {"input" => 10, "output" => 3, "cacheRead" => 0, "cacheWrite" => 0, "totalTokens" => 13}}
  message["errorMessage"] = "private fixture provider detail" if scenario == "provider-error"
  message.delete("usage") if scenario == "missing-usage"
  message["responseModel"] = "observed-model" if scenario == "observed-model"
  send_record.call({"type" => "message_end", "message" => message}) unless scenario == "end-only"
  send_record.call({"type" => "agent_end", "messages" => [message], "willRetry" => false})
  next if scenario == "no-settlement"
  send_record.call({"type" => "agent_settled", "aborted" => scenario == "aborted"})
end
exit(scenario == "nonzero" && prompted ? 7 : 0)
