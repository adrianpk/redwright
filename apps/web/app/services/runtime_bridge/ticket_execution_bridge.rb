require "digest"
require "json"
require "socket"

module RuntimeBridge
  class TicketExecutionBridge
    DEFAULT_INTENT = "change".freeze

    Result = Struct.new(
      :ok,
      :status,
      :execution_id,
      :runtime_project_ref,
      :runtime_workstream_id,
      :runtime_task_id,
      :runtime_state,
      :runtime_response,
      :error_code,
      :error_message,
      :error_details,
      keyword_init: true
    ) do
      def ok?
        ok == true
      end
    end

    class LocalSocketClient
      def initialize(socket_path:)
        @socket_path = socket_path.to_s
      end

      def request(type:, session_id:, payload:)
        line = JSON.generate(
          {
            "type" => type.to_s,
            "session_id" => session_id.to_s,
            "payload" => payload
          }
        ) + "\n"
        socket = UNIXSocket.new(@socket_path)
        socket.write(line)
        response_line = socket.gets
        raise RuntimeError, "runtime socket returned no response" if response_line.nil?

        JSON.parse(response_line)
      ensure
        socket&.close
      end
    end

    def initialize(client: nil, socket_path: nil)
      @client = client || LocalSocketClient.new(socket_path: socket_path || default_socket_path)
    end

    def start(ticket:, request_id:, actor_identifier:)
      project_setup_context = ProjectContextBuilder.new(project: ticket.project).build
      readiness = RuntimeContainers::ExecutionReadiness.new(
        project: ticket.project,
        runtime_context: project_setup_context.fetch("runtime")
      ).call
      return runtime_containers_failure(readiness) unless readiness.ok?

      request = build_request(
        ticket: ticket,
        request_id: request_id,
        actor_identifier: actor_identifier,
        project_setup_context: project_setup_context,
        runtime_containers_context: readiness.context
      )
      response = client.request(
        type: request.fetch("type"),
        session_id: request.fetch("session_id"),
        payload: request.fetch("payload")
      )
      normalize_response(ticket: ticket, request_id: request_id, request: request, response: response)
    rescue Errno::ENOENT, Errno::ECONNREFUSED
      failure(status: "failed", code: "runtime_unavailable", message: "runtime socket is not available")
    rescue StandardError => e
      failure(status: "failed", code: "runtime_bridge_failed", message: e.message)
    end

    def build_request(ticket:, request_id:, actor_identifier:, project_setup_context: nil, runtime_containers_context: nil)
      project_setup_context ||= ProjectContextBuilder.new(project: ticket.project).build
      runtime_context = project_setup_context.fetch("runtime")
      runtime_context = runtime_context.merge("runtime_containers" => runtime_containers_context) if runtime_containers_context
      project_setup_context = project_setup_context.merge("runtime" => runtime_context)

      {
        "type" => "send",
        "session_id" => "rails-ticket-#{ticket.id}",
        "payload" => {
          "channel" => "rails",
          "project_ref" => ticket.project.root_path,
          "intent" => DEFAULT_INTENT,
          "message" => ticket_execution_message(ticket, runtime_context: runtime_context),
          "project_setup_context" => project_setup_context,
          "runtime_context" => runtime_context,
          "actions" => [],
          "confirm_new_workstream" => true,
          "rails" => {
            "request_id" => request_id.to_s,
            "actor_identifier" => actor_identifier.to_s,
            "project_id" => ticket.project_id,
            "board_id" => ticket.board_id,
            "ticket_id" => ticket.id,
            "runtime_containers" => runtime_containers_context,
            "project_setup_context" => project_setup_context
          }
        }
      }
    end

    private

    attr_reader :client

    def normalize_response(ticket:, request_id:, request:, response:)
      payload = response.is_a?(Hash) && response["payload"].is_a?(Hash) ? response.fetch("payload") : response
      return failure(status: "failed", code: "runtime_error", message: payload["message"].to_s, runtime_response: payload) if payload["status"] == "error"

      runtime_task_id = payload["task_id"].presence
      execution_id = payload["execution_id"].presence || deterministic_execution_id(ticket: ticket, request_id: request_id, runtime_task_id: runtime_task_id)

      Result.new(
        ok: true,
        status: "started",
        execution_id: execution_id,
        runtime_project_ref: payload["project_id"].presence || request.dig("payload", "project_ref").to_s,
        runtime_workstream_id: payload["workstream_id"].presence,
        runtime_task_id: runtime_task_id,
        runtime_state: payload["state"].presence || "executing",
        runtime_response: payload,
        error_code: nil,
        error_message: nil,
        error_details: {}
      )
    end

    def failure(status:, code:, message:, runtime_response: {}, error_details: {})
      Result.new(
        ok: false,
        status: status,
        execution_id: nil,
        runtime_project_ref: nil,
        runtime_workstream_id: nil,
        runtime_task_id: nil,
        runtime_state: nil,
        runtime_response: runtime_response,
        error_code: code,
        error_message: message,
        error_details: error_details
      )
    end

    def runtime_containers_failure(readiness)
      failure(
        status: "failed",
        code: readiness.problems.first.fetch("code", "runtime_containers_not_ready"),
        message: readiness.operator_message,
        runtime_response: {
          "status" => "error",
          "code" => readiness.problems.first.fetch("code", "runtime_containers_not_ready"),
          "message" => readiness.operator_message,
          "runtime_containers" => readiness.context,
          "readiness_problems" => readiness.problems
        },
        error_details: {
          "runtime_containers" => readiness.context,
          "readiness_problems" => readiness.problems
        }
      )
    end

    def deterministic_execution_id(ticket:, request_id:, runtime_task_id:)
      seed = [ticket.id, request_id, runtime_task_id].compact.join(":")
      "rails-ticket-#{Digest::SHA256.hexdigest(seed)[0, 16]}"
    end

    def ticket_execution_message(ticket, runtime_context:)
      lines = [
        "Start Rails ticket ##{ticket.id}: #{ticket.title}",
        "Project: #{ticket.project.name}",
        "Board: #{ticket.board.name}",
        "Column: #{ticket.column.key}",
        "Priority: #{ticket.priority}"
      ]
      lines << "Runtime context: #{runtime_context.fetch("language_runtime")} / #{runtime_context.fetch("framework")} / #{runtime_context.fetch("container_profile")}"
      runtime_containers_context = runtime_context["runtime_containers"]
      if runtime_containers_context
        lines << "Runtime Containers: ##{runtime_containers_context["configuration_id"]} #{runtime_containers_context["readiness"]} / #{runtime_containers_context["validation_status"]}"
      end
      lines << "Assignee: #{ticket.assignee}" if ticket.assignee.present?
      lines << "Description:\n#{ticket.description}" if ticket.description.present?
      document_lines = ticket.ticket_document_links.includes(:document).map do |link|
        "- #{link.role}: #{link.document.title} (#{link.document.artifact_type}, document_id=#{link.document_id})"
      end
      lines << "Documents:\n#{document_lines.join("\n")}" if document_lines.any?
      lines.join("\n")
    end

    def default_socket_path
      configured = ENV.fetch("REDWRIGHT_RUNTIME_SOCKET_PATH", "").strip
      return configured unless configured.empty?

      Rails.root.join("..", "..", "_workspace", "redwright", "rw.sock").expand_path.to_s
    end
  end
end
