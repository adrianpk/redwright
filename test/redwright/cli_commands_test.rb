# frozen_string_literal: true

require "tmpdir"
require "stringio"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright"
require "redwright/bootstrap"

class CliCommandsTest < Minitest::Test
  def test_project_register_and_resolve_cli
    Dir.mktmpdir("redwright-cli-project-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_path = File.join(bootstrap.projects_root, "alpha")
        FileUtils.mkdir_p(project_path)

        out = StringIO.new
        err = StringIO.new
        code = Redwright::CLI.new(["project", "register", "--dev", "--path", project_path, "--alias", "alpha"], out: out, err: err).run
        assert_equal(0, code)
        assert_equal("", err.string)
        assert_match("id: ", out.string)

        out2 = StringIO.new
        err2 = StringIO.new
        code2 = Redwright::CLI.new(["project", "resolve", "--dev", "alpha"], out: out2, err: err2).run
        assert_equal(0, code2)
        assert_equal("", err2.string)
        assert_match("name: alpha", out2.string)
      end
    end
  end

  def test_workstream_create_requires_intent
    Dir.mktmpdir("redwright-cli-workstream-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_path = File.join(bootstrap.projects_root, "alpha")
        FileUtils.mkdir_p(project_path)
        Redwright::ProjectStore.new(bootstrap.db_path).register(path: project_path, aliases: ["alpha"])

        out = StringIO.new
        err = StringIO.new
        code = Redwright::CLI.new(["workstream", "create", "--dev", "--project", "alpha"], out: out, err: err).run

        assert_equal(1, code)
        assert_match("--intent", err.string)
      end
    end
  end

  def test_task_create_and_list_cli
    Dir.mktmpdir("redwright-cli-task-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_path = File.join(bootstrap.projects_root, "alpha")
        FileUtils.mkdir_p(project_path)
        project = Redwright::ProjectStore.new(bootstrap.db_path).register(path: project_path, aliases: ["alpha"])
        ws = Redwright::WorkstreamStore.new(bootstrap.db_path).create(project_id: project.id, intent: "change", state: "ready")

        out = StringIO.new
        err = StringIO.new
        code = Redwright::CLI.new([
          "task", "create", "--dev", "--workstream", ws.id, "--description", "add readme"
        ], out: out, err: err).run
        assert_equal(0, code)
        assert_equal("", err.string)
        assert_match("id: ", out.string)

        out2 = StringIO.new
        err2 = StringIO.new
        code2 = Redwright::CLI.new(["task", "list", "--dev", "--workstream", ws.id], out: out2, err: err2).run
        assert_equal(0, code2)
        assert_equal("", err2.string)
        assert_match("description: add readme", out2.string)
      end
    end
  end
end
