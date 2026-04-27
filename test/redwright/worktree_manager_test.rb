# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "open3"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/worktree_manager"

class WorktreeManagerTest < Minitest::Test
  def test_create_status_remove_worktree_for_workstream
    Dir.mktmpdir("redwright-worktree-test-") do |dir|
      Dir.chdir(dir) do
        repo_path = File.join(dir, "repo")
        setup_git_repo(repo_path)

        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)

        project = project_store.register(path: repo_path, aliases: ["rw"])
        ws = ws_store.create(project_id: project.id, intent: "change")

        manager = Redwright::WorktreeManager.new(
          project_store: project_store,
          workstream_store: ws_store,
          worktrees_root: bootstrap.worktrees_root
        )

        created = manager.create(workstream_id: ws.id, branch: "feat/worktree-test")
        assert_equal("feat/worktree-test", created.branch)
        assert(File.directory?(created.worktree_path))

        status = manager.status(workstream_id: ws.id)
        assert(status.exists)
        assert_equal(created.worktree_path, status.path)

        removed = manager.remove(workstream_id: ws.id)
        assert_nil(removed.branch)
        assert_nil(removed.worktree_path)
      end
    end
  end

  private

  def setup_git_repo(path)
    FileUtils.mkdir_p(path)
    run!("git", "-C", path, "init", "-b", "main")
    run!("git", "-C", path, "config", "user.email", "test@example.com")
    run!("git", "-C", path, "config", "user.name", "Test User")
    File.write(File.join(path, "README.md"), "# test\n")
    run!("git", "-C", path, "add", "README.md")
    run!("git", "-C", path, "commit", "-m", "init")
  end

  def run!(*cmd)
    _out, err, status = Open3.capture3(*cmd)
    raise err unless status.success?
  end
end
