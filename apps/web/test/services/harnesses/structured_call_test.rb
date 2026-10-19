require "test_helper"

class HarnessesStructuredCallTest < ActiveSupport::TestCase
  SCHEMA = {
    type: "object", required: ["tickets"], additionalProperties: false,
    properties: {tickets: {type: "array", minItems: 1, maxItems: 2, items: {"$ref" => "#/$defs/ticket"}}},
    "$defs" => {ticket: {type: "object", required: %w[title priority], additionalProperties: false,
      properties: {title: {type: "string", minLength: 1}, priority: {type: "integer", enum: [1, 2]}}}}
  }.freeze

  test "host validation checks nested constraints" do
    # The adapter double isolates host schema enforcement from model behavior.
    valid = {"tickets" => [{"title" => "Deliver billing", "priority" => 1}]}
    cases = {
      "valid local reference" => [valid, true],
      "nested type" => [{"tickets" => [{"title" => 7, "priority" => 1}]}, false],
      "nested required" => [{"tickets" => [{"title" => "Missing priority"}]}, false],
      "nested enum" => [{"tickets" => [{"title" => "Unsupported", "priority" => 3}]}, false],
      "nested extra field" => [{"tickets" => [valid["tickets"].first.merge("extra" => true)]}, false],
      "empty array" => [{"tickets" => []}, false],
      "array ceiling" => [{"tickets" => valid["tickets"] * 3}, false],
      "root extra field" => [valid.merge("extra" => true), false]
    }
    cases.each do |name, (value, accepted)|
      call = Harnesses::StructuredCall.new(adapter: ->(_) { Harnesses::Result.new(bytes: JSON.generate(value)) })
      if accepted
        result = call.call(request)
        assert_equal valid, result.value, name
        assert_equal :unknown, result.usage_status
        assert_nil result.observed_model
      else
        assert_equal :invalid_output, assert_raises(Harnesses::Error, name) { call.call(request) }.code, name
      end
    end
  end

  test "schema validation never inserts defaults" do
    # A missing model value remains missing, even when a schema supplies a default.
    schema = {type: "object", required: ["name"], properties: {name: {type: "string", default: "Invented"}}}
    call = Harnesses::StructuredCall.new(adapter: ->(_) { Harnesses::Result.new(bytes: "{}") })
    assert_equal :invalid_output, assert_raises(Harnesses::Error) { call.call(request(schema: schema)) }.code
    result = call.call(request(schema: schema.except(:required)))
    assert_equal({}, result.value)
    assert_equal "{}", result.bytes
  end

  test "invalid requests fail before invocation" do
    # Unsafe schemas and limits must not launch even a successful adapter.
    invoked = false
    call = Harnesses::StructuredCall.new(adapter: ->(_) { invoked = true })
    cases = {
      "unknown harness" => [{harness: "other"}, :unsupported_harness],
      "external reference" => [{schema: {"$ref" => "https://example.invalid/schema"}}, :invalid_schema],
      "unused external reference" => [{schema: {"$defs" => {remote: {"$ref" => "file:///unavailable"}}}}, :invalid_schema],
      "wrong dialect" => [{schema: {"$schema" => "http://json-schema.org/draft-07/schema#"}}, :invalid_schema],
      "invalid schema" => [{schema: {type: "invented"}}, :invalid_schema],
      "oversized schema" => [{schema: {description: "x" * (64 * 1024)}}, :invalid_schema],
      "oversized prompt" => [{context: {body: "x" * (1024 * 1024)}}, :request_too_large],
      "no deadline" => [{timeout: 0}, :invalid_request],
      "excess deadline" => [{timeout: 181}, :invalid_request],
      "excess result limit" => [{max_output_bytes: 2 * 1024 * 1024 + 1}, :invalid_request]
    }
    cases.each do |name, (options, code)|
      assert_equal code, assert_raises(Harnesses::Error, name) { call.call(request(**options)) }.code, name
      assert_not invoked, name
    end
  end

  test "only complete bounded JSON becomes a value" do
    # A valid fragment or a failed technical outcome cannot bypass validation.
    cases = {
      "prose" => ["Before {}", :completed, :invalid_output],
      "truncated" => ["{", :completed, :invalid_output],
      "invalid utf8" => ["\xff".b, :completed, :invalid_output],
      "oversized" => [" " * 17, :completed, :output_too_large],
      "failed outcome" => ["{}", :failed, :failed]
    }
    cases.each do |name, (bytes, outcome, code)|
      call = Harnesses::StructuredCall.new(adapter: ->(_) { Harnesses::Result.new(bytes: bytes, outcome: outcome) })
      assert_equal code, assert_raises(Harnesses::Error, name) { call.call(request(schema: {}, max_output_bytes: 16)) }.code, name
    end
  end

  test "Codex preserves its subprocess contract" do
    # A real executable checks stdin, working directory and flags without model access.
    project = create_project
    program = harness_program(project, <<~'RUBY')
      expected = ["exec", "--sandbox", "read-only", "--ephemeral", "--skip-git-repo-check", "--color", "never", "-c", 'approval_policy="never"']
      raise "changed command" unless ARGV.take(expected.length) == expected && ARGV.last == "-"
      raise "changed prompt" unless STDIN.read == "Propose tickets.\nContext:\n{}"
      raise "changed schema" unless JSON.parse(File.read(ARGV[ARGV.index("--output-schema") + 1])) == {"type" => "object"}
      raise "changed workspace" unless File.file?("test-harness")
      File.binwrite(output, "{}")
    RUBY
    result = Harnesses::StructuredCall.new.call(request(program: program, workspace: project.root_path,
      schema: {type: "object"}, max_output_bytes: 2))
    assert_equal({}, result.value)
    assert_equal :completed, result.outcome
    assert_nil result.observed_provider
    assert_nil result.usage
    assert_not File.exist?(File.read(File.join(project.root_path, "scratch-path")))
  end

  test "Codex rejects failed and invalid subprocess output" do
    # Exit status and the final file are checked together, before any value is returned.
    project = create_project
    cases = {
      "nonzero with output" => ['File.write(output, "{}"); exit 7', :failed],
      "no final file" => ["exit 0", :failed],
      "malformed JSON" => ['File.write(output, "{partial")', :invalid_output],
      "invalid UTF8" => ['File.binwrite(output, [255].pack("C"))', :invalid_output],
      "result ceiling" => ['File.write(output, " " * 17)', :output_too_large]
    }
    cases.each do |name, (source, code)|
      program = harness_program(project, source)
      error = assert_raises(Harnesses::Error, name) do
        Harnesses::StructuredCall.new.call(request(program: program, workspace: project.root_path, schema: {}, max_output_bytes: 16))
      end
      assert_equal code, error.code, name
      assert_not File.exist?(File.read(File.join(project.root_path, "scratch-path"))), name
    end
    error = assert_raises(Harnesses::Error) do
      Harnesses::StructuredCall.new.call(request(program: File.join(project.root_path, "missing"), workspace: project.root_path))
    end
    assert_equal :unavailable, error.code
  end

  test "a deadline reaps only its owned process" do
    # Use an exec replacement so the recorded PID must be gone and already reaped.
    project = create_project
    program = Pathname.new(project.root_path).join("slow-harness")
    program.write("#!/bin/sh\nprintf '%s' $$ > owned-pid\nexec sleep 30\n")
    program.chmod(0o700)
    other_pid = Process.spawn("sleep", "30", pgroup: true)
    error = assert_raises(Harnesses::Error) do
      Harnesses::StructuredCall.new.call(request(program: program.to_s, workspace: project.root_path, timeout: 0.5))
    end
    assert_equal :timed_out, error.code
    owned_pid = Integer(Pathname.new(project.root_path).join("owned-pid").read)
    assert_raises(Errno::ESRCH) { Process.kill(0, owned_pid) }
    assert_raises(Errno::ECHILD) { Process.waitpid(owned_pid, Process::WNOHANG) }
    assert_equal 1, Process.kill(0, other_pid)
  ensure
    if other_pid
      Process.kill("KILL", other_pid)
      Process.wait(other_pid)
    end
  end

  private

  def harness_program(project, source)
    path = Pathname.new(project.root_path).join("test-harness")
    path.write(<<~RUBY)
      #!/usr/bin/env ruby
      require "json"
      output = ARGV[ARGV.index("--output-last-message") + 1]
      File.write("scratch-path", File.dirname(output))
      #{source}
    RUBY
    path.chmod(0o700)
    path.to_s
  end

  def request(**options)
    Harnesses::Request.new(**{instructions: "Propose tickets.", context: {}, workspace: Dir.tmpdir,
      schema: SCHEMA, purpose: "slicing"}.merge(options))
  end
end
