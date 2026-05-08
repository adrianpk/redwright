# frozen_string_literal: true

require "json"
require "open3"
require "timeout"
require "fileutils"

require_relative "structured_patch_applier"

module Redwright
  PrimitiveExecutionResult = Struct.new(
    :action_id, :action_type, :status, :stdout, :stderr, :error_message,
    keyword_init: true
  )

  class PrimitiveExecutor
    DEFAULT_TIMEOUT_MS = 10_000
    MUTATING_ACTION_TYPES = %w[run write_file apply_patch git_branch git_commit git_push git_undo].freeze

    def initialize(allowed_projects_root: nil, enforce_mutating_projects_root: false)
      @allowed_projects_root = normalize_root(allowed_projects_root)
      @enforce_mutating_projects_root = enforce_mutating_projects_root
    end

    def execute(project_root:, action:)
      action_id = fetch(action, "id")
      action_type = fetch(action, "type")
      args = fetch(action, "args", allow_empty: true)
      timeout_ms = (action["timeout_ms"] || DEFAULT_TIMEOUT_MS).to_i
      timeout_ms = DEFAULT_TIMEOUT_MS if timeout_ms <= 0

      stdout = +""
      stderr = +""

      enforce_allowed_projects_root!(project_root: project_root, action_type: action_type)

      if action_type == "run"
        result = execute_run(project_root: project_root, args: args, timeout_ms: timeout_ms)
        return PrimitiveExecutionResult.new(
          action_id: action_id,
          action_type: action_type,
          status: result[:status],
          stdout: result[:stdout],
          stderr: result[:stderr],
          error_message: result[:error_message]
        )
      end

      Timeout.timeout(timeout_ms / 1000.0) do
        case action_type
        when "list_files"
          stdout = execute_list_files(project_root: project_root, args: args)
        when "read_file"
          stdout = execute_read_file(project_root: project_root, args: args)
        when "search"
          stdout = execute_search(project_root: project_root, args: args)
        when "write_file"
          stdout = execute_write_file(project_root: project_root, args: args)
        when "apply_patch"
          result = execute_apply_patch(project_root: project_root, args: args)
          stdout = result[:stdout]
          stderr = result[:stderr]
        when "git_status"
          result = execute_git_status(project_root: project_root, timeout_ms: timeout_ms)
          stdout = result[:stdout]
          stderr = result[:stderr]
        when "git_branch"
          result = execute_git_branch(project_root: project_root, args: args, timeout_ms: timeout_ms)
          stdout = result[:stdout]
          stderr = result[:stderr]
        when "git_commit"
          enforce_confirmation!(action: action, args: args)
          result = execute_git_commit(project_root: project_root, args: args, timeout_ms: timeout_ms)
          stdout = result[:stdout]
          stderr = result[:stderr]
        when "git_push"
          enforce_confirmation!(action: action, args: args)
          result = execute_git_push(project_root: project_root, args: args, timeout_ms: timeout_ms)
          stdout = result[:stdout]
          stderr = result[:stderr]
        when "git_undo"
          result = execute_git_undo(project_root: project_root, timeout_ms: timeout_ms)
          stdout = result[:stdout]
          stderr = result[:stderr]
        else
          raise ArgumentError, "unsupported action type: #{action_type}"
        end
      end

      PrimitiveExecutionResult.new(
        action_id: action_id,
        action_type: action_type,
        status: "ok",
        stdout: stdout,
        stderr: stderr,
        error_message: nil
      )
    rescue Timeout::Error
      PrimitiveExecutionResult.new(
        action_id: action_id,
        action_type: action_type,
        status: "error",
        stdout: stdout,
        stderr: stderr,
        error_message: "action_timeout"
      )
    rescue StandardError => e
      PrimitiveExecutionResult.new(
        action_id: action_id,
        action_type: action_type,
        status: "error",
        stdout: stdout,
        stderr: stderr,
        error_message: e.message
      )
    end

    private

    def execute_list_files(project_root:, args:)
      rel = (args["path"] || ".").to_s
      limit = (args["limit"] || 200).to_i
      limit = 200 if limit <= 0
      root = safe_path(project_root, rel)
      pattern = File.join(root, "**", "*")
      files = Dir.glob(pattern, File::FNM_DOTMATCH).select { |f| File.file?(f) }.first(limit)
      rel_paths = files.map { |f| f.sub("#{project_root}/", "") }
      JSON.generate(rel_paths)
    end

    def execute_read_file(project_root:, args:)
      path = safe_path(project_root, fetch(args, "path"))
      raise ArgumentError, "file_not_found" unless File.file?(path)

      File.read(path)
    end

    def execute_search(project_root:, args:)
      query = fetch(args, "query")
      rel = (args["path"] || ".").to_s
      root = safe_path(project_root, rel)

      if system("command -v rg >/dev/null 2>&1")
        stdout, _stderr, _status = Open3.capture3("rg", "-n", "--hidden", "--glob", "!.git", query, root)
      else
        stdout, _stderr, _status = Open3.capture3("grep", "-R", "-n", query, root)
      end
      stdout
    end

    def execute_run(project_root:, args:, timeout_ms:)
      command = fetch(args, "command")
      seconds = [(timeout_ms.to_f / 1000.0), 0.1].max.to_s
      stdout, stderr, status = Open3.capture3("timeout", "--preserve-status", seconds, "sh", "-lc", command, chdir: project_root)
      if [124, 137, 143].include?(status.exitstatus)
        return { status: "error", stdout: stdout, stderr: stderr, error_message: "action_timeout" }
      end
      raise RuntimeError, "command_failed exit=#{status.exitstatus}" unless status.success?

      { status: "ok", stdout: stdout, stderr: stderr, error_message: nil }
    end

    def execute_write_file(project_root:, args:)
      path = safe_path(project_root, fetch(args, "path"))
      content = fetch(args, "content")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      "wrote #{path.sub("#{project_root}/", "")}"
    end

    def execute_apply_patch(project_root:, args:)
      patch = fetch(args, "patch")
      return StructuredPatchApplier.new.apply(project_root: project_root, patch: patch) if StructuredPatchApplier.structured_patch?(patch)

      stdout, stderr, status = Open3.capture3("git", "apply", "--whitespace=nowarn", "-", stdin_data: patch, chdir: project_root)
      raise RuntimeError, "apply_patch_failed exit=#{status.exitstatus}" unless status.success?

      { stdout: stdout, stderr: stderr }
    end

    def execute_git_status(project_root:, timeout_ms:)
      ensure_git_repo!(project_root)
      run_git_with_timeout(project_root: project_root, timeout_ms: timeout_ms, args: %w[status --short --branch])
    end

    def execute_git_branch(project_root:, args:, timeout_ms:)
      ensure_git_repo!(project_root)
      operation = (args["operation"] || "list").to_s
      case operation
      when "list"
        run_git_with_timeout(project_root: project_root, timeout_ms: timeout_ms, args: %w[branch --list])
      when "current"
        run_git_with_timeout(project_root: project_root, timeout_ms: timeout_ms, args: %w[branch --show-current])
      when "switch"
        name = fetch(args, "name")
        run_git_with_timeout(project_root: project_root, timeout_ms: timeout_ms, args: ["switch", name])
      else
        raise ArgumentError, "unsupported_git_branch_operation"
      end
    end

    def execute_git_commit(project_root:, args:, timeout_ms:)
      ensure_git_repo!(project_root)
      message = fetch(args, "message")
      if args["add_all"] == true
        add = run_git_with_timeout(project_root: project_root, timeout_ms: timeout_ms, args: %w[add -A])
        commit = run_git_with_timeout(project_root: project_root, timeout_ms: timeout_ms, args: ["commit", "-m", message])
        return { stdout: "#{add[:stdout]}#{commit[:stdout]}", stderr: "#{add[:stderr]}#{commit[:stderr]}" }
      end
      run_git_with_timeout(project_root: project_root, timeout_ms: timeout_ms, args: ["commit", "-m", message])
    end

    def execute_git_push(project_root:, args:, timeout_ms:)
      ensure_git_repo!(project_root)
      remote = args["remote"].to_s.strip
      branch = args["branch"].to_s.strip
      command = ["push"]
      command << remote unless remote.empty?
      command << branch unless branch.empty?
      run_git_with_timeout(project_root: project_root, timeout_ms: timeout_ms, args: command)
    end

    def execute_git_undo(project_root:, timeout_ms:)
      ensure_git_repo!(project_root)
      status = run_git_with_timeout(project_root: project_root, timeout_ms: timeout_ms, args: %w[status --porcelain])
      lines = status[:stdout].to_s.split("\n")
      untracked = lines.select { |line| line.start_with?("?? ") }
      unless untracked.empty?
        raise RuntimeError, "undo_blocked_untracked_files"
      end
      if lines.empty?
        return { stdout: "nothing_to_undo\n", stderr: "" }
      end

      restore = run_git_with_timeout(project_root: project_root, timeout_ms: timeout_ms, args: %w[restore --staged --worktree :/])
      { stdout: restore[:stdout], stderr: restore[:stderr] }
    end

    def run_git_with_timeout(project_root:, timeout_ms:, args:)
      seconds = [(timeout_ms.to_f / 1000.0), 0.1].max.to_s
      stdout, stderr, status = Open3.capture3("timeout", "--preserve-status", seconds, "git", *args, chdir: project_root)
      raise RuntimeError, "git_action_timeout" if [124, 137, 143].include?(status.exitstatus)
      raise RuntimeError, "git_command_failed:#{args.first} exit=#{status.exitstatus}" unless status.success?

      { stdout: stdout, stderr: stderr }
    end

    def ensure_git_repo!(project_root)
      _stdout, _stderr, status = Open3.capture3("git", "rev-parse", "--is-inside-work-tree", chdir: project_root)
      raise RuntimeError, "not_a_git_repository" unless status.success?
    end

    def enforce_confirmation!(action:, args:)
      requires_confirmation = action["requires_confirmation"] == true
      confirmed = args["confirmed"] == true
      return if requires_confirmation && confirmed

      raise ArgumentError, "confirmation_required"
    end

    def fetch(hash, key, allow_empty: false)
      value = hash[key]
      raise ArgumentError, "missing_#{key}" if value.nil?
      raise ArgumentError, "missing_#{key}" if !allow_empty && value.respond_to?(:empty?) && value.empty?

      value
    end

    def safe_path(project_root, raw_path)
      root = File.expand_path(project_root)
      candidate = File.expand_path(raw_path.to_s, root)
      return candidate if candidate == root
      return candidate if candidate.start_with?("#{root}/")

      raise ArgumentError, "path_outside_project_root"
    end

    def enforce_allowed_projects_root!(project_root:, action_type:)
      return unless @enforce_mutating_projects_root
      return unless MUTATING_ACTION_TYPES.include?(action_type)
      return if @allowed_projects_root.nil?

      root = File.expand_path(project_root)
      return if root == @allowed_projects_root
      return if root.start_with?("#{@allowed_projects_root}/")

      raise ArgumentError, "unsafe_project_root: #{root} (allowed root: #{@allowed_projects_root})"
    end

    def normalize_root(path)
      return nil if path.nil?
      trimmed = path.to_s.strip
      return nil if trimmed.empty?

      File.expand_path(trimmed)
    end
  end
end
