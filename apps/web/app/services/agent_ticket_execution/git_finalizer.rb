module AgentTicketExecution
  class GitFinalizer
    FORBIDDEN_MARKERS = %w[redwright rw/].freeze
    DEFAULT_COMMIT_PREFIX = "feat".freeze

    Result = Struct.new(:ok, :code, :message, :branch_name, :commit_message, :action_results, keyword_init: true) do
      def ok?
        ok == true
      end

      def commit_sha
        stdout = action_results.find { |result| result.fetch("type") == "git_commit" }&.fetch("stdout", "")
        stdout.to_s[/\[[^\s]+ ([a-f0-9]+)\]/, 1]
      end

      def to_h
        {
          "ok" => ok?,
          "code" => code,
          "message" => message,
          "branch_name" => branch_name,
          "commit_message" => commit_message,
          "commit_sha" => commit_sha,
          "action_results" => action_results
        }
      end
    end

    def finalize(ticket:, request:, workspace:, validation_result:)
      return skipped("validation_not_completed") unless validation_result&.completed?

      branch_name = branch_name_for(ticket, request, workspace)
      commit_message = commit_message_for(ticket)
      guard_no_redwright_marker!(branch_name, "branch_name")
      guard_no_redwright_marker!(commit_message, "commit_message")

      switch = execute(workspace, "branch", "run", {"command" => switch_command(branch_name)})
      return failure("branch_failed", switch, branch_name, commit_message, [switch]) unless switch.fetch("status") == "ok"

      commit = execute(
        workspace,
        "commit",
        "git_commit",
        {"message" => commit_message, "add_all" => true, "confirmed" => true},
        requires_confirmation: true
      )
      actions = [switch, commit]
      return failure("commit_failed", commit, branch_name, commit_message, actions) unless commit.fetch("status") == "ok"

      Result.new(
        ok: true,
        code: "committed",
        message: "Local commit created.",
        branch_name: branch_name,
        commit_message: commit_message,
        action_results: actions
      )
    rescue ArgumentError => e
      Result.new(
        ok: false,
        code: "invalid_git_finalization",
        message: e.message,
        branch_name: nil,
        commit_message: nil,
        action_results: []
      )
    end

    private

    def branch_name_for(ticket, request, workspace)
      suffix = ticket.display_key.parameterize.presence || ticket.id
      request["branch_name"].presence || workspace.branch_name.presence || "ticket-#{suffix}"
    end

    def commit_message_for(ticket)
      "#{DEFAULT_COMMIT_PREFIX}(ticket): #{ticket.title.to_s.strip}"
    end

    def switch_command(branch_name)
      "git switch #{shell_escape(branch_name)} 2>/dev/null || git switch -c #{shell_escape(branch_name)}"
    end

    def execute(workspace, id, type, args, requires_confirmation: false)
      result = workspace.primitive_executor.execute(
        project_root: workspace.workspace_path,
        action: {
          "id" => id,
          "type" => type,
          "args" => args,
          "requires_confirmation" => requires_confirmation,
          "timeout_ms" => 30_000
        }
      )
      {
        "id" => result.action_id,
        "type" => result.action_type,
        "status" => result.status,
        "stdout" => result.stdout,
        "stderr" => result.stderr,
        "error_message" => result.error_message
      }
    end

    def failure(code, result, branch_name, commit_message, actions)
      Result.new(
        ok: false,
        code: code,
        message: result.fetch("error_message").presence || code,
        branch_name: branch_name,
        commit_message: commit_message,
        action_results: actions
      )
    end

    def skipped(code)
      Result.new(ok: true, code: code, message: "Git finalization skipped.", branch_name: nil, commit_message: nil, action_results: [])
    end

    def guard_no_redwright_marker!(value, field)
      lowered = value.to_s.downcase
      return unless FORBIDDEN_MARKERS.any? { |marker| lowered.include?(marker) }

      raise ArgumentError, "#{field}_contains_redwright_marker"
    end

    def shell_escape(value)
      "'#{value.to_s.gsub("'", "'\"'\"'")}'"
    end
  end
end
