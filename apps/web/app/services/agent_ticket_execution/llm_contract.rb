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
      When blocked, set status to blocked and provide a concrete blocking_reason.
    PROMPT

    Result = Struct.new(:ok, :code, :message, :payload, keyword_init: true) do
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

      status = payload["status"].to_s
      return failure("invalid_status", "status must be one of: #{STATUSES.join(', ')}", payload) unless STATUSES.include?(status)
      return failure("missing_summary", "summary is required", payload) if payload["summary"].to_s.strip.empty?
      if status == "blocked" && payload["blocking_reason"].to_s.strip.empty?
        return failure("missing_blocking_reason", "blocking_reason is required when status is blocked", payload)
      end

      array_error = array_field_error(payload)
      return array_error if array_error

      Result.new(ok: true, code: "ok", message: "valid", payload: normalize(payload))
    end

    private

    ARRAY_FIELDS = %w[files commands actions validation_expectations post_actions warnings affected_files].freeze

    def array_field_error(payload)
      ARRAY_FIELDS.each do |field|
        next if payload[field].nil? || payload[field].is_a?(Array)

        return failure("invalid_#{field}", "#{field} must be an array", payload)
      end
      nil
    end

    def normalize(payload)
      {
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
    end

    def failure(code, message, payload)
      Result.new(ok: false, code: code, message: message, payload: payload)
    end
  end
end
