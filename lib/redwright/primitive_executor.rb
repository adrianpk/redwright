# frozen_string_literal: true

require "json"
require "open3"
require "timeout"
require "fileutils"

module Redwright
  PrimitiveExecutionResult = Struct.new(
    :action_id, :action_type, :status, :stdout, :stderr, :error_message,
    keyword_init: true
  )

  class PrimitiveExecutor
    DEFAULT_TIMEOUT_MS = 10_000

    def execute(project_root:, action:)
      action_id = fetch(action, "id")
      action_type = fetch(action, "type")
      args = fetch(action, "args")
      timeout_ms = (action["timeout_ms"] || DEFAULT_TIMEOUT_MS).to_i
      timeout_ms = DEFAULT_TIMEOUT_MS if timeout_ms <= 0

      stdout = +""
      stderr = +""

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
      stdout, stderr, status = Open3.capture3("git", "apply", "--whitespace=nowarn", "-", stdin_data: patch, chdir: project_root)
      raise RuntimeError, "apply_patch_failed exit=#{status.exitstatus}" unless status.success?

      { stdout: stdout, stderr: stderr }
    end

    def fetch(hash, key)
      value = hash[key]
      raise ArgumentError, "missing_#{key}" if value.nil? || (value.respond_to?(:empty?) && value.empty?)

      value
    end

    def safe_path(project_root, raw_path)
      root = File.expand_path(project_root)
      candidate = File.expand_path(raw_path.to_s, root)
      return candidate if candidate == root
      return candidate if candidate.start_with?("#{root}/")

      raise ArgumentError, "path_outside_project_root"
    end
  end
end
