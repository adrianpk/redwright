# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/workspace_snapshot_builder"

class WorkspaceSnapshotBuilderTest < Minitest::Test
  def test_build_includes_tree_and_significant_files
    Dir.mktmpdir("redwright-workspace-snapshot-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      FileUtils.mkdir_p(File.join(dir, "test"))
      File.write(File.join(dir, "README.md"), "# sample")
      File.write(File.join(dir, "Gemfile"), "source 'https://rubygems.org'")
      File.write(File.join(dir, "lib", "app.rb"), "puts 'ok'")
      File.write(File.join(dir, "test", "app_test.rb"), "puts 'test'")

      snapshot = Redwright::WorkspaceSnapshotBuilder.new.build(project_path: dir)
      assert_includes(snapshot, "Workspace root:")
      assert_includes(snapshot, "Tree (")
      assert_includes(snapshot, "Significant files (")
      assert_includes(snapshot, "README.md")
      assert_includes(snapshot, "lib/app.rb")
    end
  end
end
