module AgentTicketExecution
  class LlmContract
    ACTION = "agent_ticket_execution".freeze
    MODEL_ROLE = "coding".freeze
    RENDERED_TEXT_FIELD = "summary".freeze
    STATUSES = %w[proposed_changes needs_correction blocked].freeze

    OUTPUT_CONTRACT = {
      "rendered_text_field" => RENDERED_TEXT_FIELD,
      "required_fields" => %w[status summary]
    }.freeze

    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are implementing a repository ticket inside a bounded RedWright agent workspace.
      Return only JSON matching the requested contract.
      Do not claim that changes were applied; describe the files, commands, and actions RedWright should apply.
      Use existing repository protocols and validation expectations from the provided context.
      For file edits, return either files with full replacement content or files with an apply_patch-compatible patch.
      Prefer the smallest complete change that satisfies the ticket and tests.
      Include validation commands RedWright should run, such as go test ./..., in commands when relevant.
      When blocked, set status to blocked and provide a concrete blocking_reason.
      Use this exact shape for executable changes:
      {"status":"proposed_changes","summary":"...","files":[{"path":"main.go","patch":"*** Begin Patch..."}],"commands":[{"command":"go test ./...","purpose":"validate"}]}
      Do not use status ready, changes, or commands[].cmd.
    PROMPT

    Result = Struct.new(:ok, :code, :message, :payload, :normalizations, keyword_init: true) do
      def ok?
        ok == true
      end
    end

    def self.output_contract
      OUTPUT_CONTRACT
    end

    def self.system_prompt
      SYSTEM_PROMPT
    end

    def validate(payload)
      return failure("invalid_payload", "response payload must be an object", payload) unless payload.is_a?(Hash)

      normalized_payload, normalizations = normalize_near_misses(payload)
      status = normalized_payload["status"].to_s
      return failure("invalid_status", "status must be one of: #{STATUSES.join(', ')}", normalized_payload, normalizations: normalizations) unless STATUSES.include?(status)
      return failure("missing_summary", "summary is required", normalized_payload, normalizations: normalizations) if normalized_payload["summary"].to_s.strip.empty?
      if status == "blocked" && normalized_payload["blocking_reason"].to_s.strip.empty?
        return failure("missing_blocking_reason", "blocking_reason is required when status is blocked", normalized_payload, normalizations: normalizations)
      end

      array_error = array_field_error(normalized_payload, normalizations: normalizations)
      return array_error if array_error

      Result.new(ok: true, code: "ok", message: "valid", payload: normalize(normalized_payload, normalizations: normalizations), normalizations: normalizations)
    end

    private

    ARRAY_FIELDS = %w[files commands actions validation_expectations post_actions warnings affected_files].freeze
    STATUS_ALIASES = {
      "ready" => "proposed_changes"
    }.freeze

    def normalize_near_misses(payload)
      normalized = deep_dup_payload(payload)
      normalizations = []

      if STATUS_ALIASES.key?(normalized["status"].to_s)
        original = normalized["status"].to_s
        normalized["status"] = STATUS_ALIASES.fetch(original)
        normalizations << {"field" => "status", "from" => original, "to" => normalized["status"]}
      end

      if normalized["files"].nil? && normalized["changes"].is_a?(Array)
        normalized["files"] = normalize_change_files(normalized["changes"], normalizations)
        normalizations << {"field" => "changes", "to" => "files"}
      end

      if normalized["commands"].is_a?(Array)
        normalized["commands"] = normalized["commands"].map.with_index do |command, index|
          normalize_command(command, index, normalizations)
        end
      end

      [normalized, normalizations]
    end

    def normalize_change_files(changes, normalizations)
      changes.map.with_index do |change, index|
        next change unless change.is_a?(Hash)

        file = change.dup
        file.delete("type")
        normalizations << {"field" => "changes[#{index}].type", "action" => "dropped"} if change.key?("type")
        file
      end
    end

    def normalize_command(command, index, normalizations)
      return command unless command.is_a?(Hash)
      return command if command.key?("command") || !command.key?("cmd")

      normalized = command.dup
      normalized["command"] = normalized.delete("cmd")
      normalizations << {"field" => "commands[#{index}].cmd", "to" => "commands[#{index}].command"}
      normalized
    end

    def deep_dup_payload(payload)
      Marshal.load(Marshal.dump(payload))
    rescue TypeError
      payload.deep_dup
    end

    def array_field_error(payload, normalizations: [])
      ARRAY_FIELDS.each do |field|
        next if payload[field].nil? || payload[field].is_a?(Array)

        return failure("invalid_#{field}", "#{field} must be an array", payload, normalizations: normalizations)
      end
      nil
    end

    def normalize(payload, normalizations: [])
      normalized = {
        "status" => payload.fetch("status").to_s,
        "summary" => payload.fetch("summary").to_s,
        "files" => Array(payload["files"]),
        "commands" => Array(payload["commands"]),
        "actions" => Array(payload["actions"]),
        "validation_expectations" => Array(payload["validation_expectations"]),
        "post_actions" => Array(payload["post_actions"]),
        "warnings" => Array(payload["warnings"]),
        "affected_files" => Array(payload["affected_files"]),
        "blocking_reason" => payload["blocking_reason"],
        "retry_instruction" => payload["retry_instruction"]
      }
      normalized["contract_normalizations"] = normalizations unless normalizations.empty?
      normalized
    end

    def failure(code, message, payload, normalizations: [])
      Result.new(ok: false, code: code, message: message, payload: payload, normalizations: normalizations)
    end
  end
end
