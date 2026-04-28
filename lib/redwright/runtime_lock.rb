# frozen_string_literal: true

require "json"
require "time"

module Redwright
  class RuntimeLock
    LockInfo = Struct.new(:pid, :acquired_at, :lock_path, keyword_init: true)

    def initialize(lock_path:, pid_provider: -> { Process.pid }, now_provider: -> { Time.now.utc.iso8601(6) })
      @lock_path = lock_path
      @pid_provider = pid_provider
      @now_provider = now_provider
      @locked = false
    end

    def acquire!
      existing = current_info
      if existing && pid_alive?(existing.pid)
        raise RuntimeError, "runtime lock already held by pid=#{existing.pid}"
      end

      write_lock(pid: @pid_provider.call, acquired_at: @now_provider.call)
      @locked = true
      current_info
    end

    def release!
      return unless @locked

      File.delete(@lock_path) if File.exist?(@lock_path)
      @locked = false
    end

    def current_info
      return nil unless File.file?(@lock_path)

      raw = JSON.parse(File.read(@lock_path))
      LockInfo.new(
        pid: raw.fetch("pid").to_i,
        acquired_at: raw.fetch("acquired_at").to_s,
        lock_path: @lock_path
      )
    rescue JSON::ParserError, KeyError, TypeError
      nil
    end

    def running?
      info = current_info
      return false unless info

      pid_alive?(info.pid)
    end

    private

    def write_lock(pid:, acquired_at:)
      File.write(@lock_path, JSON.generate({ "pid" => pid, "acquired_at" => acquired_at }))
    end

    def pid_alive?(pid)
      return false if pid.to_i <= 0

      Process.kill(0, pid)
      true
    rescue Errno::ESRCH
      false
    rescue Errno::EPERM
      true
    end
  end
end
