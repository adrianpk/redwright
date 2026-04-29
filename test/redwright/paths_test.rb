# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/paths"

class PathsTest < Minitest::Test
  def test_dev_mode_always_uses_workspace_projects_root
    Dir.mktmpdir("redwright-paths-dev-") do |dir|
      paths = Redwright::Paths.new(mode: :dev, pwd: dir)
      assert_equal(File.join(dir, "_workspace", "Projects"), paths.resolve_projects_root("/tmp/ignored"))
      assert_equal(File.join(dir, "_workspace", "Projects"), paths.resolve_projects_root("relative/ignored"))
    end
  end

  def test_real_mode_requires_absolute_projects_root
    Dir.mktmpdir("redwright-paths-real-") do |home|
      paths = Redwright::Paths.new(mode: :real, home: home)
      err = assert_raises(ArgumentError) { paths.resolve_projects_root("relative/path") }
      assert_equal("invalid config key: default_projects_root must be absolute in real mode", err.message)
    end
  end

  def test_runtime_state_root_is_partitioned_by_runtime
    Dir.mktmpdir("redwright-paths-runtime-") do |dir|
      paths = Redwright::Paths.new(mode: :dev, pwd: dir)

      assert_equal(
        File.join(dir, "_workspace", "redwright", "runtimes", "interactive"),
        paths.runtime_state_root("interactive")
      )
      assert_equal(
        File.join(dir, "_workspace", "redwright", "runtimes", "factory"),
        paths.runtime_state_root("factory")
      )
    end
  end

  def test_runtime_state_root_rejects_unknown_runtime
    Dir.mktmpdir("redwright-paths-runtime-invalid-") do |dir|
      paths = Redwright::Paths.new(mode: :dev, pwd: dir)
      err = assert_raises(ArgumentError) { paths.runtime_state_root("other") }
      assert_equal("unsupported runtime: other", err.message)
    end
  end
end
