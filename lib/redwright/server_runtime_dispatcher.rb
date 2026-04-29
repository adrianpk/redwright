# frozen_string_literal: true
require "fileutils"

module Redwright
  class ServerRuntimeDispatcher
    def initialize(flow:, blocked_retry_attempts: 1, project_store: nil, projects_root: nil)
      @flow = flow
      @blocked_retry_attempts = blocked_retry_attempts
      @project_store = project_store
      @projects_root = projects_root
      @session_project_refs = {}
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
        dispatch_send(request: request, payload: payload)
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

    def dispatch_send(request:, payload:)
      session_id = request.fetch("session_id", "").to_s
      message = payload.fetch("message").to_s
      project_ref = payload.fetch("project_ref", "").to_s.strip
      project_ref, message = resolve_project_ref_for_send(session_id: session_id, project_ref: project_ref, message: message)
      raise ArgumentError, "missing_project_ref" if project_ref.to_s.strip.empty?

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
    rescue StandardError => e
      {
        "status" => "error",
        "message" => e.message,
        "error_class" => e.class.to_s
      }
    end

    def resolve_project_ref_for_send(session_id:, project_ref:, message:)
      return [project_ref, message] unless @project_store

      parsed = parse_project_slash(message)
      if parsed
        case parsed[:command]
        when "new"
          created = create_project(parsed[:name])
          @session_project_refs[session_id] = created.id unless session_id.empty?
          return [created.id, "Create a new project named '#{parsed[:name]}' and set it active."]
        when "switch"
          target = @project_store.resolve(parsed[:name]) || @project_store.resolve("project:#{parsed[:name]}")
          raise ArgumentError, "project not found: #{parsed[:name]}" unless target

          @session_project_refs[session_id] = target.id unless session_id.empty?
          return [target.id, "Switch active project to '#{parsed[:name]}'."]
        end
      end

      resolved = @project_store.resolve(project_ref)
      return [resolved.id, message] if resolved

      session_project_ref = session_id.empty? ? nil : @session_project_refs[session_id]
      if session_project_ref
        session_project = @project_store.resolve(session_project_ref)
        return [session_project.id, message] if session_project
      end

      active = @project_store.resolve(nil)
      return [active.id, message] if active

      [project_ref, message]
    end

    def parse_project_slash(message)
      raw = message.to_s.strip
      return nil unless raw.start_with?("/project ")

      match = raw.match(%r{\A/project\s+(new|switch)\s+([a-zA-Z0-9._\-]+)\s*\z}i)
      return nil unless match

      { command: match[1].downcase, name: match[2] }
    end

    def create_project(name)
      raise ArgumentError, "missing project name" if name.to_s.strip.empty?
      raise ArgumentError, "missing projects root" if @projects_root.to_s.strip.empty?

      path = File.join(@projects_root, name)
      FileUtils.mkdir_p(path)
      @project_store.register(path: path, aliases: [name])
    end
  end
end
