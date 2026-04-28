# frozen_string_literal: true

module Redwright
  class ServerRuntimeDispatcher
    def initialize(flow:, blocked_retry_attempts: 1)
      @flow = flow
      @blocked_retry_attempts = blocked_retry_attempts
    end

    def call(request)
      type = request.fetch("type").to_s
      payload = request.fetch("payload")

      case type
      when "ctl"
        dispatch_ctl(payload)
      when "subscribe"
        {
          "status" => "subscribed",
          "channel" => payload.fetch("channel", "unknown").to_s
        }
      when "send"
        dispatch_send(payload)
      else
        raise ArgumentError, "unsupported_request_type"
      end
    end

    private

    def dispatch_ctl(payload)
      command = payload.fetch("command").to_s
      case command
      when "status"
        {
          "status" => "ok",
          "command" => "status",
          "message" => "server runtime ready"
        }
      when "stop", "resume", "trace"
        {
          "status" => "ok",
          "command" => command,
          "message" => "accepted"
        }
      else
        raise ArgumentError, "unsupported_ctl_command"
      end
    end

    def dispatch_send(payload)
      project_ref = payload.fetch("project_ref").to_s.strip
      raise ArgumentError, "missing_project_ref" if project_ref.empty?

      message = payload.fetch("message").to_s
      intent = payload.fetch("intent", "change").to_s
      actions = payload.fetch("actions", [])
      result = @flow.process(
        project_ref: project_ref,
        intent: intent,
        message: message,
        actions: actions,
        workstream_id: payload["workstream_id"],
        confirm_new_workstream: payload.fetch("confirm_new_workstream", true) == true,
        blocked_retry_attempts: @blocked_retry_attempts
      )
      {
        "status" => "ok",
        "project_id" => result.project.id,
        "workstream_id" => result.workstream.id,
        "task_id" => result.task.id,
        "state" => result.workstream.state,
        "terminal_reason" => result.terminal_reason.to_s,
        "action_results" => (result.action_results || []).map do |r|
          {
            "action_id" => r.action_id,
            "action_type" => r.action_type,
            "status" => r.status,
            "error_message" => r.error_message
          }
        end
      }
    end
  end
end
