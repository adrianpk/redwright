# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/primitive_executor"

class PrimitiveExecutorTest < Minitest::Test
  def test_write_and_read_file_within_project_root
    Dir.mktmpdir("redwright-primitive-executor-rw-") do |dir|
      executor = Redwright::PrimitiveExecutor.new

      write_result = executor.execute(
        project_root: dir,
        action: {
          "id" => "a1",
          "type" => "write_file",
          "args" => { "path" => "notes/todo.txt", "content" => "hello" },
          "timeout_ms" => 2_000,
          "on_failure" => "abort"
        }
      )
      assert_equal("ok", write_result.status)
      assert(File.file?(File.join(dir, "notes/todo.txt")))

      read_result = executor.execute(
        project_root: dir,
        action: {
          "id" => "a2",
          "type" => "read_file",
          "args" => { "path" => "notes/todo.txt" },
          "timeout_ms" => 2_000,
          "on_failure" => "abort"
        }
      )
      assert_equal("ok", read_result.status)
      assert_equal("hello", read_result.stdout)
    end
  end

  def test_rejects_paths_outside_project_root
    Dir.mktmpdir("redwright-primitive-executor-boundary-") do |dir|
      executor = Redwright::PrimitiveExecutor.new

      result = executor.execute(
        project_root: dir,
        action: {
          "id" => "a1",
          "type" => "read_file",
          "args" => { "path" => "../secrets.txt" },
          "timeout_ms" => 2_000,
          "on_failure" => "abort"
        }
      )

      assert_equal("error", result.status)
      assert_match("path_outside_project_root", result.error_message)
    end
  end

  def test_run_respects_timeout_policy
    Dir.mktmpdir("redwright-primitive-executor-timeout-") do |dir|
      executor = Redwright::PrimitiveExecutor.new

      result = executor.execute(
        project_root: dir,
        action: {
          "id" => "a1",
          "type" => "run",
          "args" => { "command" => "sleep 1" },
          "timeout_ms" => 50,
          "on_failure" => "abort"
        }
      )

      assert_equal("error", result.status)
      assert_equal("action_timeout", result.error_message)
    end
  end
end
