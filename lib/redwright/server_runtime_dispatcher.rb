# frozen_string_literal: true
require "fileutils"
require "open3"
require "time"
require "uri"
require "yaml"
require_relative "project_new_mediator"

module Redwright
  class ServerRuntimeDispatcher
    def initialize(flow:, blocked_retry_attempts: 1, project_store: nil, projects_root: nil, task_store: nil, action_execution_store: nil, project_new_mediator: nil)
      @flow = flow
      @blocked_retry_attempts = blocked_retry_attempts
      @project_store = project_store
      @projects_root = projects_root
      @task_store = task_store
      @action_execution_store = action_execution_store
      @project_new_mediator = project_new_mediator || ProjectNewMediator.new
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
      channel = payload.fetch("channel", "").to_s
      project_ref = payload.fetch("project_ref", "").to_s.strip
      project_ref, message, operational = resolve_project_ref_for_send(
        session_id: session_id,
        project_ref: project_ref,
        message: message,
        operational_intent: payload["operational_intent"],
        operational_args: payload["operational_args"]
      )
      if operational
        read_only = dispatch_read_only_operational(session_id: session_id, project_ref: project_ref, operational: operational)
        return read_only if read_only
      end
      raise ArgumentError, "missing_project_ref" if project_ref.to_s.strip.empty?

      ticketization = ticketize_ad_hoc_message(channel: channel, message: message)
      message = ticketization[:message]

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
        "command" => operational ? operational[:command].to_s : nil,
        "project_id" => result.project.id,
        "workstream_id" => result.workstream.id,
        "task_id" => result.task.id,
        "state" => result.workstream.state,
        "ticketized" => ticketization[:ticketized],
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

    def dispatch_read_only_operational(session_id:, project_ref:, operational:)
      case operational[:command]
      when "list"
        projects = @project_store ? @project_store.list : []
        return {
          "status" => "ok",
          "command" => "project_list",
          "projects" => projects.map do |project|
            {
              "id" => project.id,
              "name" => project.name,
              "aliases" => project.aliases,
              "path" => project.path
            }
          end
        }
      when "where"
        active = resolve_active_project(session_id: session_id, project_ref: project_ref)
        raise ArgumentError, "missing_project_ref" unless active

        return {
          "status" => "ok",
          "command" => "project_where",
          "project_id" => active.id,
          "project_name" => active.name,
          "project_path" => active.path
        }
      when "status"
        active = resolve_active_project(session_id: session_id, project_ref: project_ref)
        raise ArgumentError, "missing_project_ref" unless active

        output, status = Open3.capture2e("git", "-C", active.path.to_s, "status", "--short", "--branch")
        raise ArgumentError, "git status failed for active project" unless status.success?

        return {
          "status" => "ok",
          "command" => "repo_status",
          "project_id" => active.id,
          "project_name" => active.name,
          "git_status" => output.to_s.strip
        }
      when "ticket_list"
        active = resolve_active_project(session_id: session_id, project_ref: project_ref)
        raise ArgumentError, "missing_project_ref" unless active
        raise ArgumentError, "task_store_not_available" unless @task_store

        tickets = @task_store.list_recent_with_trace(limit: 50).select { |row| row.project_id == active.id }
        return {
          "status" => "ok",
          "command" => "ticket_list",
          "project_id" => active.id,
          "project_name" => active.name,
          "tickets" => tickets.first(20).map do |row|
            {
              "id" => row.task_id,
              "description" => row.task_description,
              "status" => row.task_status,
              "workstream_id" => row.workstream_id,
              "created_at" => row.created_at
            }
          end
        }
      end

      nil
    end

    def resolve_project_ref_for_send(session_id:, project_ref:, message:, operational_intent: nil, operational_args: nil)
      return [project_ref, message, nil] unless @project_store

      parsed = parse_explicit_operational(intent: operational_intent, args: operational_args)
      parsed ||= parse_operational_slash(message)
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
        when "ticket_list"
          active = resolve_active_project(session_id: session_id, project_ref: project_ref)
          return [active.id, message, parsed] if active
        when "ticket_pick"
          active = resolve_active_project(session_id: session_id, project_ref: project_ref)
          return [active.id, "Pick next ticket and start execution.", parsed] if active
        when "ticket_start"
          active = resolve_active_project(session_id: session_id, project_ref: project_ref)
          return [active.id, "Start working on ticket #{parsed[:ticket_id]}.", parsed] if active
        when "loop_start"
          active = resolve_active_project(session_id: session_id, project_ref: project_ref)
          return [active.id, "Enable ticket loop mode and continue with the next eligible ticket.", parsed] if active
        when "loop_stop"
          active = resolve_active_project(session_id: session_id, project_ref: project_ref)
          return [active.id, "Stop ticket loop mode after current task boundary.", parsed] if active
        when "list"
          return [project_ref, message, parsed]
        when "where", "status"
          active = resolve_active_project(session_id: session_id, project_ref: project_ref)
          return [active.id, message, parsed] if active
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

    def parse_explicit_operational(intent:, args:)
      op = intent.to_s.strip
      return nil if op.empty? || op == "none"

      parsed_project_new = @project_new_mediator.parse_operational_intent(intent: op, args: args)
      return parsed_project_new if parsed_project_new

      operational_args = args.is_a?(Hash) ? args : {}
      case op
      when "project_switch"
        name = operational_args["project_ref"].to_s.strip
        name = operational_args["name"].to_s.strip if name.empty?
        return nil if name.empty?

        { command: "switch", name: name }
      when "project_list"
        { command: "list" }
      when "project_where"
        { command: "where" }
      when "repo_status"
        { command: "status" }
      when "repo_undo"
        { command: "undo" }
      when "repo_clone"
        url = operational_args["repo_url"].to_s.strip
        url = operational_args["url"].to_s.strip if url.empty?
        return nil if url.empty?

        name = operational_args["project_name"].to_s.strip
        name = operational_args["name"].to_s.strip if name.empty?
        name = infer_repo_name(url) if name.empty?
        { command: "clone", url: url, name: name }
      else
        nil
      end
    end

    def parse_operational_slash(message)
      raw = message.to_s.strip
      if raw.start_with?("/project ")
        parsed_project_new = @project_new_mediator.parse_project_slash(raw: raw)
        return parsed_project_new if parsed_project_new

        project_match = raw.match(%r{\A/project\s+(switch)\s+([a-zA-Z0-9._\-]+)\s*\z}i)
        return { command: "list" } if raw.match?(%r{\A/project\s+list\s*\z}i)
        return { command: "where" } if raw.match?(%r{\A/project\s+where\s*\z}i)
        return nil unless project_match

        return { command: project_match[1].downcase, name: project_match[2] }
      end

      if raw.start_with?("/repo ")
        return { command: "undo" } if raw.match?(%r{\A/repo\s+undo\s*\z}i)
        return { command: "status" } if raw.match?(%r{\A/repo\s+status\s*\z}i)
        clone_match = raw.match(%r{\A/repo\s+clone\s+(\S+)(?:\s+as\s+([a-zA-Z0-9._\-]+))?\s*\z}i)
        if clone_match
          url = clone_match[1]
          explicit_name = clone_match[2].to_s.strip
          return { command: "clone", url: url, name: explicit_name.empty? ? infer_repo_name(url) : explicit_name }
        end
      end

      if raw.start_with?("/ticket ")
        return { command: "ticket_list" } if raw.match?(%r{\A/ticket\s+list\s*\z}i)
        return { command: "ticket_pick" } if raw.match?(%r{\A/ticket\s+pick\s*\z}i)
        start_match = raw.match(%r{\A/ticket\s+start\s+([a-zA-Z0-9._\-]+)\s*\z}i)
        return { command: "ticket_start", ticket_id: start_match[1] } if start_match
      end

      if raw.start_with?("/loop ")
        return { command: "loop_start" } if raw.match?(%r{\A/loop\s+start\s*\z}i)
        return { command: "loop_stop" } if raw.match?(%r{\A/loop\s+stop\s*\z}i)
      end

      nil
    end

    def ticketize_ad_hoc_message(channel:, message:)
      raw = message.to_s.strip
      return { ticketized: false, message: raw } if raw.empty?
      return { ticketized: false, message: raw } if raw.start_with?("/")
      return { ticketized: false, message: raw } unless %w[telegram tui].include?(channel)

      {
        ticketized: true,
        message: "Ticket request: #{raw}"
      }
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
      project = @project_store.register(path: path, aliases: [name], source_type: source_type, source_ref: source_ref)
      write_project_manifest_if_missing(project: project, created_via: source_type == "local_new" ? "new" : "clone")
      project
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

      project = @project_store.register(path: path, aliases: [name], source_type: "remote_clone", source_ref: url.to_s)
      write_project_manifest_if_missing(
        project: project,
        created_via: "clone",
        provenance: {
          "remote_url" => url.to_s,
          "provider" => infer_provider_from_url(url.to_s),
          "ref" => infer_head_ref(path)
        }
      )
      project
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

    def write_project_manifest_if_missing(project:, created_via:, provenance: nil)
      manifest_dir = File.join(project.path, ".redwright")
      manifest_path = File.join(manifest_dir, "manifest.yml")
      return if File.file?(manifest_path)

      FileUtils.mkdir_p(manifest_dir)
      manifest = {
        "schema_version" => 1,
        "project" => {
          "id" => project.id,
          "name" => project.name,
          "slug" => normalize_slug(project.name),
          "stack" => "unknown",
          "created_via" => created_via,
          "created_at" => Time.now.utc.iso8601
        }
      }
      manifest["provenance"] = provenance if provenance.is_a?(Hash) && !provenance.empty?
      File.write(manifest_path, YAML.dump(manifest))
    end

    def normalize_slug(name)
      slug = name.to_s.downcase.gsub(/[^a-z0-9._\-]+/, "-").gsub(/\A-+|-+\z/, "")
      slug.empty? ? "project" : slug
    end

    def infer_provider_from_url(url)
      host = begin
        URI.parse(url).host.to_s.downcase
      rescue URI::InvalidURIError
        ""
      end
      return "github" if host.include?("github")
      return "codeberg" if host.include?("codeberg")
      return "gitlab" if host.include?("gitlab")

      host.empty? ? "unknown" : host
    end

    def infer_head_ref(path)
      out, status = Open3.capture2("git", "-C", path.to_s, "symbolic-ref", "--quiet", "--short", "HEAD")
      return "HEAD" unless status.success?

      value = out.to_s.strip
      value.empty? ? "HEAD" : value
    rescue StandardError
      "HEAD"
    end
  end
end
