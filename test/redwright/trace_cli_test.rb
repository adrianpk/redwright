# frozen_string_literal: true

require "tmpdir"
require "stringio"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright"
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"
require "redwright/action_execution_store"
require "redwright/trace"

class TraceCliTest < Minitest::Test
  def test_trace_recent_and_show_return_turn_evidence
    Dir.mktmpdir("redwright-trace-cli-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        tasks = Redwright::TaskStore.new(bootstrap.db_path)
        actions = Redwright::ActionExecutionStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        ws = workstreams.create(project_id: project.id, intent: "change", state: "executing")
        task = nil
        Redwright::Trace.with_trace_id("trc-cli-1") do
          task = tasks.create(workstream_id: ws.id, description: "run trace cli", status: "pending")
          actions.create(task_id: task.id, action_id: "a1", action_type: "list_files", status: "ok")
        end

        recent_out = StringIO.new
        recent_err = StringIO.new
        recent_code = Redwright::CLI.new(["trace", "recent", "--dev", "--limit", "10"], out: recent_out, err: recent_err).run
        assert_equal(0, recent_code)
        assert_equal("", recent_err.string)
        assert_includes(recent_out.string, "trace_id: trc-cli-1")

        show_out = StringIO.new
        show_err = StringIO.new
        show_code = Redwright::CLI.new(["trace", "show", "--dev", "trc-cli-1"], out: show_out, err: show_err).run
        assert_equal(0, show_code)
        assert_equal("", show_err.string)
        assert_includes(show_out.string, "tasks:")
        assert_includes(show_out.string, "actions:")
        assert_includes(show_out.string, "action_id: a1")
      end
    end
  end
end
