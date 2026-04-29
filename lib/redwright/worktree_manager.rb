# frozen_string_literal: true

require "open3"
require "fileutils"
require_relative "worktree_lock_manager"

module Redwright
  WorktreeStatus = Struct.new(:exists, :path, :branch, keyword_init: true)

  class WorktreeManager
    def initialize(project_store:, workstream_store:, worktrees_root:, lock_manager: nil)
      @project_store = project_store
      @workstream_store = workstream_store
      @worktrees_root = worktrees_root
      @lock_manager = lock_manager || WorktreeLockManager.new(locks_root: File.join(@worktrees_root, ".locks"))
    end

    def create(workstream_id:, branch:)
      with_worktree_lock(workstream_id) do
        ws = @workstream_store.get(workstream_id)
        raise ArgumentError, "workstream not found" unless ws

        project = @project_store.get(ws.project_id)
        raise ArgumentError, "project not found" unless project

        path = File.join(@worktrees_root, ws.id)
        if File.directory?(path)
          return @workstream_store.attach_checkout(ws.id, branch: branch, worktree_path: path)
        end

        FileUtils.mkdir_p(@worktrees_root)
        run!("git", "-C", project.path, "worktree", "add", "-b", branch, path)
        @workstream_store.attach_checkout(ws.id, branch: branch, worktree_path: path)
      end
    end

    def remove(workstream_id:)
      with_worktree_lock(workstream_id) do
        ws = @workstream_store.get(workstream_id)
        raise ArgumentError, "workstream not found" unless ws
        return ws unless ws.worktree_path && !ws.worktree_path.empty?

        project = @project_store.get(ws.project_id)
        raise ArgumentError, "project not found" unless project

        run!("git", "-C", project.path, "worktree", "remove", "--force", ws.worktree_path)
        @workstream_store.detach_checkout(ws.id)
      end
    end

    def status(workstream_id:)
      ws = @workstream_store.get(workstream_id)
      raise ArgumentError, "workstream not found" unless ws

      exists = ws.worktree_path && File.directory?(ws.worktree_path)
      WorktreeStatus.new(exists: !!exists, path: ws.worktree_path, branch: ws.branch)
    end

    private

    def with_worktree_lock(workstream_id)
      @lock_manager.with_lock(workstream_id) { yield }
    end

    def run!(*cmd)
      _out, err, status = Open3.capture3(*cmd)
      return if status.success?

      raise ArgumentError, err.strip.empty? ? "command failed: #{cmd.join(' ')}" : err.strip
    end
  end
end
