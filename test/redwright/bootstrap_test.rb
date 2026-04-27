# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"

class BootstrapTest < Minitest::Test
  def test_bootstrap_creates_dev_workspace_directories_and_db
    Dir.mktmpdir("redwright-test-") do |dir|
      Dir.chdir(dir) do
        result = Redwright::Bootstrap.new(mode: :dev).call

        assert_path(File.join(dir, "_workspace", ".redwright"), result.state_dir)
        assert_path(File.join(dir, "_workspace", ".config", "redwright"), result.config_dir)
        assert_path(File.join(dir, "_workspace", "Projects"), result.projects_root)
        assert_path(File.join(dir, "_workspace", "Projects", ".worktrees"), result.worktrees_root)
        assert_path(File.join(dir, "_workspace", ".redwright", "runtime.db"), result.db_path)

        assert(File.directory?(result.state_dir))
        assert(File.directory?(result.config_dir))
        assert(File.directory?(result.projects_root))
        assert(File.directory?(result.worktrees_root))
        assert(File.file?(result.db_path))
      end
    end
  end

  private

  def assert_path(expected, actual)
    assert_equal(expected, actual)
  end
end
