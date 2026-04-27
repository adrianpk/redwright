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

  def test_git_status_and_git_branch_list_in_repo
    Dir.mktmpdir("redwright-primitive-executor-git-status-") do |dir|
      setup_git_repo(dir)
      File.write(File.join(dir, "README.md"), "hello\n")
      system("git -C #{dir} add README.md")
      system("git -C #{dir} commit -m 'init' >/dev/null 2>&1")
      File.write(File.join(dir, "README.md"), "hello2\n")

      executor = Redwright::PrimitiveExecutor.new
      status = executor.execute(
        project_root: dir,
        action: {
          "id" => "g1",
          "type" => "git_status",
          "args" => {},
          "timeout_ms" => 2_000,
          "on_failure" => "abort"
        }
      )
      assert_equal("ok", status.status)
      assert_includes(status.stdout, "README.md")

      branches = executor.execute(
        project_root: dir,
        action: {
          "id" => "g2",
          "type" => "git_branch",
          "args" => { "operation" => "list" },
          "timeout_ms" => 2_000,
          "on_failure" => "abort"
        }
      )
      assert_equal("ok", branches.status)
      assert_match(/\*\s+main|\*\s+master/, branches.stdout)
    end
  end

  def test_git_commit_requires_confirmation
    Dir.mktmpdir("redwright-primitive-executor-git-confirm-") do |dir|
      setup_git_repo(dir)
      File.write(File.join(dir, "x.txt"), "x\n")

      executor = Redwright::PrimitiveExecutor.new
      denied = executor.execute(
        project_root: dir,
        action: {
          "id" => "g3",
          "type" => "git_commit",
          "args" => { "message" => "x", "add_all" => true, "confirmed" => false },
          "requires_confirmation" => true,
          "timeout_ms" => 2_000,
          "on_failure" => "abort"
        }
      )
      assert_equal("error", denied.status)
      assert_match("confirmation_required", denied.error_message)

      allowed = executor.execute(
        project_root: dir,
        action: {
          "id" => "g4",
          "type" => "git_commit",
          "args" => { "message" => "x", "add_all" => true, "confirmed" => true },
          "requires_confirmation" => true,
          "timeout_ms" => 2_000,
          "on_failure" => "abort"
        }
      )
      assert_equal("ok", allowed.status)
    end
  end

  def test_git_push_error_mapping_when_no_remote
    Dir.mktmpdir("redwright-primitive-executor-git-push-") do |dir|
      setup_git_repo(dir)
      File.write(File.join(dir, "x.txt"), "x\n")
      system("git -C #{dir} add -A")
      system("git -C #{dir} commit -m 'x' >/dev/null 2>&1")

      executor = Redwright::PrimitiveExecutor.new
      result = executor.execute(
        project_root: dir,
        action: {
          "id" => "g5",
          "type" => "git_push",
          "args" => { "confirmed" => true },
          "requires_confirmation" => true,
          "timeout_ms" => 2_000,
          "on_failure" => "abort"
        }
      )

      assert_equal("error", result.status)
      assert_match("git_command_failed:push", result.error_message)
    end
  end

  private

  def setup_git_repo(dir)
    system("git -C #{dir} init -q")
    system("git -C #{dir} config user.email 'test@example.com'")
    system("git -C #{dir} config user.name 'Test User'")
  end
end
