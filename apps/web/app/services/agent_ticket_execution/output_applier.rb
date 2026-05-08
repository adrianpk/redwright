module AgentTicketExecution
  class OutputApplier
    ALLOWED_DIRECT_ACTION_TYPES = %w[list_files read_file search write_file apply_patch run git_status].freeze

    Result = Struct.new(:ok, :code, :message, :action_results, :affected_files, keyword_init: true) do
      def ok?
        ok == true
      end

      def to_h
        {
          "ok" => ok?,
          "code" => code,
          "message" => message,
          "affected_files" => affected_files,
          "action_results" => action_results.map(&:to_h)
        }
      end
    end

    ActionResult = Struct.new(:id, :type, :status, :stdout, :stderr, :error_message, keyword_init: true) do
      def ok?
        status == "ok"
      end

      def to_h
        {
          "id" => id,
          "type" => type,
          "status" => status,
          "stdout" => stdout,
          "stderr" => stderr,
          "error_message" => error_message
        }
      end
    end

    def apply(payload:, workspace:)
      actions = build_actions(payload)
      return failure("no_actions", "LLM output did not include applicable files, commands, or actions") if actions.empty?

      results = []
      actions.each do |action|
        primitive_result = workspace.primitive_executor.execute(
          project_root: workspace.workspace_path,
          action: action
        )
        result = normalize_result(primitive_result)
        results << result
        return failure("primitive_failed", result.error_message, action_results: results) unless result.ok?
      end

      Result.new(
        ok: true,
        code: "applied",
        message: "LLM output applied.",
        action_results: results,
        affected_files: affected_files(payload)
      )
    rescue ArgumentError => e
      failure("invalid_output", e.message)
    end

    private

    def build_actions(payload)
      file_actions(payload.fetch("files", [])) +
        command_actions(payload.fetch("commands", [])) +
        direct_actions(payload.fetch("actions", []))
    end

    def file_actions(files)
      files.each_with_index.map do |file, index|
        path = file.fetch("path")
        if file.key?("content")
          primitive_action("file-#{index + 1}", "write_file", "path" => path, "content" => file.fetch("content"))
        elsif file.key?("patch")
          primitive_action("file-#{index + 1}", "apply_patch", "patch" => file.fetch("patch"))
        else
          raise ArgumentError, "file_#{index + 1}_missing_content_or_patch"
        end
      end
    end

    def command_actions(commands)
      commands.each_with_index.map do |command, index|
        primitive_action(
          "command-#{index + 1}",
          "run",
          "command" => command.fetch("command")
        )
      end
    end

    def direct_actions(actions)
      actions.each_with_index.map do |action, index|
        type = action.fetch("type").to_s
        raise ArgumentError, "unsupported_action_type: #{type}" unless ALLOWED_DIRECT_ACTION_TYPES.include?(type)

        primitive_action(
          action["id"].presence || "action-#{index + 1}",
          type,
          action.fetch("args", {})
        )
      end
    end

    def primitive_action(id, type, args)
      {
        "id" => id,
        "type" => type,
        "args" => args,
        "timeout_ms" => 30_000
      }
    end

    def normalize_result(result)
      ActionResult.new(
        id: result.action_id,
        type: result.action_type,
        status: result.status,
        stdout: result.stdout,
        stderr: result.stderr,
        error_message: result.error_message
      )
    end

    def affected_files(payload)
      explicit = Array(payload["affected_files"])
      return explicit.map(&:to_s) unless explicit.empty?

      Array(payload["files"]).filter_map { |file| file["path"].to_s.presence }
    end

    def failure(code, message, action_results: [])
      Result.new(
        ok: false,
        code: code,
        message: message,
        action_results: action_results,
        affected_files: []
      )
    end
  end
end
