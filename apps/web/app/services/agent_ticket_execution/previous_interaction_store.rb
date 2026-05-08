require "digest"
require "fileutils"
require "json"
require "time"

module AgentTicketExecution
  class PreviousInteractionStore
    DEFAULT_ROOT = Rails.root.join("tmp", "redwright", "agent-ticket-interactions").freeze
    DEFAULT_LIMIT = 20

    def initialize(root: DEFAULT_ROOT)
      @root = File.expand_path(root.to_s)
    end

    def append(ticket:, request:, request_payload:, response_payload:, outcome: nil, failure_summary: nil, context_section_names: [])
      path = path_for(ticket)
      FileUtils.mkdir_p(File.dirname(path))
      record = {
        "schema_version" => 1,
        "created_at" => Time.now.utc.iso8601(6),
        "operation_kind" => "agent_ticket_execution",
        "project_id" => ticket.project_id,
        "ticket_id" => ticket.id,
        "session_id" => session_id(request),
        "agent_id" => agent_id(request),
        "source" => "agent_llm_loop",
        "request_payload" => request_payload,
        "response_payload" => response_payload,
        "outcome" => outcome,
        "failure_summary" => failure_summary,
        "context_section_names" => Array(context_section_names).map(&:to_s)
      }
      File.open(path, "a") { |file| file.puts(JSON.generate(record)) }
      record
    end

    def recent(ticket:, request:, limit: DEFAULT_LIMIT)
      path = path_for(ticket)
      return [] unless File.file?(path)

      File.readlines(path, chomp: true)
        .filter_map { |line| parse_record(line) }
        .select { |record| matching_session?(record, request) }
        .last(limit)
    end

    private

    attr_reader :root

    def path_for(ticket)
      File.join(root, "#{digest(ticket.project_id)}", "ticket-#{digest(ticket.id)}.jsonl")
    end

    def digest(value)
      Digest::SHA256.hexdigest(value.to_s)[0, 24]
    end

    def parse_record(line)
      parsed = JSON.parse(line)
      parsed.is_a?(Hash) ? parsed : nil
    rescue JSON::ParserError
      nil
    end

    def matching_session?(record, request)
      record["operation_kind"] == "agent_ticket_execution" &&
        record["source"] == "agent_llm_loop" &&
        record["session_id"].to_s == session_id(request).to_s &&
        record["agent_id"].to_s == agent_id(request).to_s
    end

    def session_id(request)
      request["session_id"].presence || "ticket-#{request['ticket_id'] || 'pickup'}"
    end

    def agent_id(request)
      request["agent_id"].presence || request["actor_identifier"].presence || "agent-ticket-executor"
    end
  end
end
