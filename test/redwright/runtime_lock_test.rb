# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/runtime_lock"

class RuntimeLockTest < Minitest::Test
  def test_acquire_and_release_lock
    Dir.mktmpdir("redwright-runtime-lock-") do |dir|
      lock_path = File.join(dir, "runtime.lock")
      lock = Redwright::RuntimeLock.new(lock_path: lock_path)

      info = lock.acquire!
      assert_equal(Process.pid, info.pid)
      assert_equal(true, File.file?(lock_path))
      assert_equal(true, lock.running?)

      lock.release!
      assert_equal(false, File.exist?(lock_path))
    end
  end

  def test_replaces_stale_lock
    Dir.mktmpdir("redwright-runtime-lock-stale-") do |dir|
      lock_path = File.join(dir, "runtime.lock")
      File.write(lock_path, "{\"pid\":999999,\"acquired_at\":\"2026-01-01T00:00:00Z\"}")

      lock = Redwright::RuntimeLock.new(lock_path: lock_path)
      info = lock.acquire!

      assert_equal(Process.pid, info.pid)
      assert_equal(true, lock.running?)
      lock.release!
    end
  end

  def test_rejects_live_lock_when_pid_is_running
    Dir.mktmpdir("redwright-runtime-lock-live-") do |dir|
      lock_path = File.join(dir, "runtime.lock")
      File.write(lock_path, "{\"pid\":#{Process.pid},\"acquired_at\":\"2026-01-01T00:00:00Z\"}")
      lock = Redwright::RuntimeLock.new(lock_path: lock_path)

      err = assert_raises(RuntimeError) { lock.acquire! }
      assert_match("runtime lock already held by pid=", err.message)
    end
  end
end
