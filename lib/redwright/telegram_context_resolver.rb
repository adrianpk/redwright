# frozen_string_literal: true
require "fileutils"

module Redwright
  class TelegramContextResolver
    Resolution = Struct.new(:resolved, :project_ref, :project_path, :workstream_id, :question, keyword_init: true)

    def initialize(project_store:, chat_context_store:, projects_root: nil, default_project_dirname: "project-1", clarification_session_store: nil)
      @project_store = project_store
      @chat_context_store = chat_context_store
      @projects_root = projects_root
      @default_project_dirname = default_project_dirname
      @clarification_session_store = clarification_session_store
    end

    def resolve(chat_id:, text:)
      pending = resolve_pending_gap(chat_id: chat_id, text: text)
      return pending if pending

      explicit_matches = explicit_project_matches(text.to_s)
      if explicit_matches.size > 1
        return Resolution.new(
          resolved: false,
          project_ref: nil,
          project_path: nil,
          workstream_id: nil,
          question: "I found multiple project matches. Please specify one project id/alias explicitly."
        )
      end

      if explicit_matches.size == 1
        project = explicit_matches.first
        context = @chat_context_store.get(chat_id)
        if context && context.project_id != project.id
          return Resolution.new(
            resolved: false,
            project_ref: nil,
            project_path: nil,
            workstream_id: nil,
            question: "Session is bound to another active project. Use '/project switch #{project.name}' to switch explicitly before mutating requests."
          )
        end
        return Resolution.new(
          resolved: true,
          project_ref: project.id,
          project_path: project.path,
          workstream_id: context&.project_id == project.id ? context.workstream_id : nil,
          question: nil
        )
      end

      context = @chat_context_store.get(chat_id)
      if context
        project = @project_store.get(context.project_id)
        if project
          return Resolution.new(
            resolved: true,
            project_ref: project.id,
            project_path: project.path,
            workstream_id: context.workstream_id,
            question: nil
          )
        end
      end

      single = only_project
      return Resolution.new(resolved: true, project_ref: single.id, project_path: single.path, workstream_id: nil, question: nil) if single

      inferred_name = infer_project_name(text.to_s)
      if inferred_name
        @clarification_session_store&.open_project_name_confirm(
          chat_id: chat_id,
          workstream_id: context&.workstream_id,
          suggested_project_name: inferred_name,
          question_id: "project_name_confirm"
        )
        return Resolution.new(
          resolved: false,
          project_ref: nil,
          project_path: nil,
          workstream_id: nil,
          question: "No active project context found. I inferred project name '#{inferred_name}'. Reply 'yes' to confirm or provide a different project name."
        )
      end

      bootstrapped = bootstrap_first_run(chat_id: chat_id)
      return bootstrapped if bootstrapped

      Resolution.new(
        resolved: false,
        project_ref: nil,
        project_path: nil,
        workstream_id: nil,
        question: "No active project context found. Please specify a project id or alias."
      )
    end

    private

    def resolve_pending_gap(chat_id:, text:)
      pending = @clarification_session_store&.get_open(chat_id: chat_id)
      return nil unless pending

      if pending.gap_type == "project_name_confirm"
        suggested_name = pending.payload.fetch("suggested_project_name", "").to_s
        if confirmation_reply?(text)
          project = register_or_get_project_by_name(suggested_name)
          @chat_context_store.upsert(chat_id: chat_id, project_id: project.id, workstream_id: nil)
          @clarification_session_store&.advance(
            chat_id: chat_id,
            session_id: pending.id,
            resolved_fields: { "project_name" => suggested_name },
            status: "closed",
            last_question_id: "project_name_confirm"
          )
          return Resolution.new(
            resolved: true,
            project_ref: project.id,
            project_path: project.path,
            workstream_id: nil,
            question: nil
          )
        end

        suggested = infer_project_name(text.to_s) || infer_replacement_name(text.to_s) || sanitize_project_name(text.to_s)
        if suggested && !suggested.empty?
          project = register_or_get_project_by_name(suggested)
          @chat_context_store.upsert(chat_id: chat_id, project_id: project.id, workstream_id: nil)
          @clarification_session_store&.advance(
            chat_id: chat_id,
            session_id: pending.id,
            resolved_fields: { "project_name" => suggested },
            status: "closed",
            last_question_id: "project_name_confirm"
          )
          return Resolution.new(
            resolved: true,
            project_ref: project.id,
            project_path: project.path,
            workstream_id: nil,
            question: nil
          )
        end

        return Resolution.new(
          resolved: false,
          project_ref: nil,
          project_path: nil,
          workstream_id: nil,
          question: "Please confirm the inferred project name '#{suggested_name}' with 'yes' or provide a different project name."
        )
      end

      nil
    end

    def only_project
      projects = @project_store.list
      return nil unless projects.size == 1

      projects.first
    end

    def bootstrap_first_run(chat_id:)
      return nil if @projects_root.nil? || @projects_root.strip.empty?
      return nil unless @project_store.list.empty?

      candidate_paths = discover_candidate_project_paths
      return nil if candidate_paths.size > 1

      selected_path = candidate_paths.first || create_default_project_path
      project = @project_store.register(path: selected_path)
      @chat_context_store.upsert(chat_id: chat_id, project_id: project.id, workstream_id: nil)
      Resolution.new(
        resolved: true,
        project_ref: project.id,
        project_path: project.path,
        workstream_id: nil,
        question: nil
      )
    end

    def discover_candidate_project_paths
      return [] unless Dir.exist?(@projects_root)

      Dir.children(@projects_root)
        .sort
        .reject { |entry| entry.start_with?(".") || entry == ".worktrees" }
        .map { |entry| File.join(@projects_root, entry) }
        .select { |path| File.directory?(path) }
    end

    def create_default_project_path
      path = File.join(@projects_root, @default_project_dirname)
      FileUtils.mkdir_p(path)
      path
    end

    def explicit_project_matches(text)
      projects = @project_store.list
      down = text.downcase

      matches = projects.select do |project|
        tokens_for(project).any? do |token|
          token_match?(down, token)
        end
      end
      matches.uniq { |p| p.id }
    end

    def tokens_for(project)
      ([project.id, project.name] + project.aliases).compact.map(&:downcase).uniq
    end

    def token_match?(text, token)
      return false if token.nil? || token.empty?
      return true if text == token
      return true if text.include?("project:#{token}")
      return true if text.include?("project=#{token}")

      text.match?(/(^|[^a-z0-9_\-])#{Regexp.escape(token)}([^a-z0-9_\-]|$)/)
    end

    def infer_project_name(text)
      normalized = text.to_s.strip
      return nil if normalized.empty?

      patterns = [
        /named\s+([a-z0-9][a-z0-9._\-]+)/i,
        /llamado\s+([a-z0-9][a-z0-9._\-]+)/i,
        /project\s+([a-z0-9][a-z0-9._\-]+)/i,
        /proyecto\s+([a-z0-9][a-z0-9._\-]+)/i
      ]
      patterns.each do |regex|
        match = normalized.match(regex)
        next unless match

        inferred = sanitize_project_name(match[1].to_s)
        return inferred unless inferred.nil? || inferred.empty?
      end
      nil
    end

    def sanitize_project_name(value)
      cleaned = value.to_s.downcase.gsub(/[^a-z0-9._\-]/, "-").gsub(/-+/, "-").gsub(/\A-|-+\z/, "")
      cleaned.empty? ? nil : cleaned
    end

    def infer_replacement_name(text)
      normalized = text.to_s.strip
      return nil if normalized.empty?

      patterns = [
        /use\s+([a-z0-9][a-z0-9._\-]+)/i,
        /project\s+([a-z0-9][a-z0-9._\-]+)/i,
        /proyecto\s+([a-z0-9][a-z0-9._\-]+)/i
      ]
      patterns.each do |regex|
        match = normalized.match(regex)
        next unless match

        inferred = sanitize_project_name(match[1].to_s)
        return inferred unless inferred.nil? || inferred.empty?
      end
      nil
    end

    def confirmation_reply?(text)
      normalized = text.to_s.strip.downcase
      %w[yes y si sí dale ok okay confirm confirmado].include?(normalized)
    end

    def register_or_get_project_by_name(name)
      normalized = sanitize_project_name(name)
      raise ArgumentError, "invalid project name" if normalized.nil? || normalized.empty?
      existing = @project_store.list.find { |p| tokens_for(p).include?(normalized) }
      return existing if existing

      path = if @projects_root && !@projects_root.to_s.strip.empty?
               FileUtils.mkdir_p(@projects_root)
               File.join(@projects_root, normalized)
             else
               File.expand_path(normalized)
             end
      FileUtils.mkdir_p(path)
      @project_store.register(path: path, aliases: [normalized])
    end
  end
end
