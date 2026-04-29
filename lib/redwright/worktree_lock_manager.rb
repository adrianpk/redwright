# frozen_string_literal: true

require "json"
require "fileutils"
require "time"

module Redwright
  class WorktreeLockError < StandardError; end

  class WorktreeLockManager
    def initialize(locks_root:)
      @locks_root = locks_root
      FileUtils.mkdir_p(@locks_root)
    end

    def with_lock(lock_id)
      lock_path = File.join(@locks_root, "#{lock_id}.lock")
      acquire(lock_path)
      begin
        yield
      ensure
        release(lock_path)
      end
    end

    private

    def acquire(lock_path)
      payload = {
        "pid" => Process.pid,
        "acquired_at" => Time.now.utc.iso8601
      }
      File.write(lock_path, JSON.generate(payload), mode: "wx")
    rescue Errno::EEXIST
      stale_recovered = recover_stale_lock(lock_path)
      retry if stale_recovered

      owner_pid = lock_owner_pid(lock_path)
      raise WorktreeLockError, "worktree_locked pid=#{owner_pid}"
    end

    def recover_stale_lock(lock_path)
      pid = lock_owner_pid(lock_path)
      return true if pid.nil? && delete_lock(lock_path)

      return false if process_alive?(pid)

      delete_lock(lock_path)
    end

    def release(lock_path)
      File.delete(lock_path) if File.exist?(lock_path)
    end

    def delete_lock(lock_path)
      File.delete(lock_path)
      true
    rescue Errno::ENOENT
      true
    end

    def lock_owner_pid(lock_path)
      payload = JSON.parse(File.read(lock_path))
      Integer(payload["pid"])
    rescue StandardError
      nil
    end

    def process_alive?(pid)
      return false if pid.nil?

      Process.kill(0, pid)
      true
    rescue Errno::ESRCH
      false
    rescue Errno::EPERM
      true
    end
  end
end
