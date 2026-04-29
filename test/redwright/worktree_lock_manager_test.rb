# frozen_string_literal: true

require "tmpdir"
require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/worktree_lock_manager"

class WorktreeLockManagerTest < Minitest::Test
  def test_raises_when_lock_is_held_by_live_process
    Dir.mktmpdir("redwright-lock-manager-") do |dir|
      manager = Redwright::WorktreeLockManager.new(locks_root: dir)
      lock_path = File.join(dir, "ws-1.lock")
      File.write(lock_path, JSON.generate({ "pid" => Process.pid, "acquired_at" => Time.now.utc.iso8601 }))

      assert_raises(Redwright::WorktreeLockError) do
        manager.with_lock("ws-1") { flunk("lock should not be acquired") }
      end
    end
  end

  def test_recovers_stale_lock_and_acquires
    Dir.mktmpdir("redwright-lock-manager-") do |dir|
      manager = Redwright::WorktreeLockManager.new(locks_root: dir)
      lock_path = File.join(dir, "ws-2.lock")
      File.write(lock_path, JSON.generate({ "pid" => 999_999, "acquired_at" => Time.now.utc.iso8601 }))

      entered = false
      manager.with_lock("ws-2") { entered = true }

      assert_equal(true, entered)
      refute(File.exist?(lock_path))
    end
  end
end

