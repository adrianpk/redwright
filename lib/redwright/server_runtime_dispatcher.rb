# frozen_string_literal: true
require "fileutils"
require "uri"

module Redwright
  class ServerRuntimeDispatcher
    def initialize(flow:, blocked_retry_attempts: 1, project_store: nil, projects_root: nil, task_store: nil, action_execution_store: nil)
      @flow = flow
      @blocked_retry_attempts = blocked_retry_attempts
      @project_store = project_store
      @projects_root = projects_root
      @task_store = task_store
      @action_execution_store = action_execution_store
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
      project_ref, message, operational = resolve_project_ref_for_send(session_id: session_id, project_ref: project_ref, message: message)
      raise ArgumentError, "missing_project_ref" if project_ref.to_s.strip.empty?

      intent = payload.fetch("intent", "change").to_s
      actions = payload.fetch("actions", [])
      if operational && operational[:command] == "undo"
        enforce_repo_undo_contract!(project_ref)
        actions = [{
          "id" => "repo_undo_last_safe_change",
          "type" => "git_undo",
          "args" => {},
          "requires_confirmation" => false,
          "timeout_ms" => 20_000,
          "on_failure" => "abort"
        }]
      end
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
      return [project_ref, message, nil] unless @project_store

      parsed = parse_operational_slash(message)
      if parsed
        case parsed[:command]
        when "new"
          created = create_project(parsed[:name], source_type: "local_new", source_ref: "")
          @session_project_refs[session_id] = created.id unless session_id.empty?
          return [created.id, "Create a new project named '#{parsed[:name]}' and set it active.", parsed]
        when "switch"
          target = @project_store.resolve(parsed[:name]) || @project_store.resolve("project:#{parsed[:name]}")
          raise ArgumentError, "project not found: #{parsed[:name]}" unless target

          @session_project_refs[session_id] = target.id unless session_id.empty?
          return [target.id, "Switch active project to '#{parsed[:name]}'.", parsed]
        when "clone"
          cloned = clone_project(parsed[:url], parsed[:name])
          @session_project_refs[session_id] = cloned.id unless session_id.empty?
          return [cloned.id, "Clone repository '#{parsed[:url]}' and set project '#{cloned.name}' active.", parsed]
        when "undo"
          active = resolve_active_project(session_id: session_id, project_ref: project_ref)
          return [active.id, "Undo the latest safe repository changes for the active project.", parsed] if active
        end
      end

      resolved = @project_store.resolve(project_ref)
      return [resolved.id, message, nil] if resolved

      session_project_ref = session_id.empty? ? nil : @session_project_refs[session_id]
      if session_project_ref
        session_project = @project_store.resolve(session_project_ref)
        return [session_project.id, message, nil] if session_project
      end

      active = @project_store.resolve(nil)
      return [active.id, message, nil] if active

      [project_ref, message, nil]
    end

    def parse_operational_slash(message)
      raw = message.to_s.strip
      if raw.start_with?("/project ")
        project_match = raw.match(%r{\A/project\s+(new|switch)\s+([a-zA-Z0-9._\-]+)\s*\z}i)
        return nil unless project_match

        return { command: project_match[1].downcase, name: project_match[2] }
      end

      if raw.start_with?("/repo ")
        return { command: "undo" } if raw.match?(%r{\A/repo\s+undo\s*\z}i)
        clone_match = raw.match(%r{\A/repo\s+clone\s+(\S+)(?:\s+as\s+([a-zA-Z0-9._\-]+))?\s*\z}i)
        if clone_match
          url = clone_match[1]
          explicit_name = clone_match[2].to_s.strip
          return { command: "clone", url: url, name: explicit_name.empty? ? infer_repo_name(url) : explicit_name }
        end
      end

      nil
    end

    def resolve_active_project(session_id:, project_ref:)
      resolved = @project_store.resolve(project_ref)
      return resolved if resolved

      session_project_ref = session_id.empty? ? nil : @session_project_refs[session_id]
      return @project_store.resolve(session_project_ref) if session_project_ref

      @project_store.resolve(nil)
    end

    def enforce_repo_undo_contract!(project_ref)
      return unless @task_store && @action_execution_store

      project = @project_store.resolve(project_ref)
      return unless project

      latest = @task_store.list_recent_with_trace(limit: 200).find { |row| row.project_id == project.id }
      return unless latest

      action_types = @action_execution_store.list(task_id: latest.task_id).map(&:action_type)
      return if action_types.empty?

      has_git = action_types.any? { |type| type.to_s.start_with?("git_") }
      has_non_git = action_types.any? { |type| !type.to_s.start_with?("git_") }

      if has_git && has_non_git
        raise ArgumentError, "undo_blocked_mixed_git_and_non_git_actions"
      end
      if has_non_git
        raise ArgumentError, "undo_not_supported_for_non_git_actions"
      end
    end

    def create_project(name, source_type:, source_ref:)
      raise ArgumentError, "missing project name" if name.to_s.strip.empty?
      raise ArgumentError, "missing projects root" if @projects_root.to_s.strip.empty?

      path = File.join(@projects_root, name)
      FileUtils.mkdir_p(path)
      @project_store.register(path: path, aliases: [name], source_type: source_type, source_ref: source_ref)
    end

    def clone_project(url, name)
      raise ArgumentError, "missing repository url" if url.to_s.strip.empty?
      raise ArgumentError, "missing project name" if name.to_s.strip.empty?
      raise ArgumentError, "missing projects root" if @projects_root.to_s.strip.empty?

      path = File.join(@projects_root, name)
      FileUtils.mkdir_p(@projects_root)
      unless File.directory?(File.join(path, ".git"))
        raise ArgumentError, "target path already exists and is not a git repository: #{path}" if File.exist?(path)

        system("git", "clone", url.to_s, path.to_s, out: File::NULL, err: File::NULL)
        raise ArgumentError, "git clone failed: #{url}" unless $?.success?
      end

      @project_store.register(path: path, aliases: [name], source_type: "remote_clone", source_ref: url.to_s)
    end

    def infer_repo_name(url)
      parsed = URI.parse(url.to_s)
      base = File.basename(parsed.path.to_s)
      base = base.sub(/\.git\z/i, "")
      slug = base.downcase.gsub(/[^a-z0-9._\-]+/, "-").gsub(/\A-+|-+\z/, "")
      raise ArgumentError, "could not infer repository name from url: #{url}" if slug.empty?

      slug
    rescue URI::InvalidURIError
      base = File.basename(url.to_s)
      base = base.sub(/\.git\z/i, "")
      slug = base.downcase.gsub(/[^a-z0-9._\-]+/, "-").gsub(/\A-+|-+\z/, "")
      raise ArgumentError, "could not infer repository name from url: #{url}" if slug.empty?

      slug
    end
  end
end
