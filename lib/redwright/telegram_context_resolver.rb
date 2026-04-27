# frozen_string_literal: true

module Redwright
  class TelegramContextResolver
    Resolution = Struct.new(:resolved, :project_ref, :project_path, :workstream_id, :question, keyword_init: true)

    def initialize(project_store:, chat_context_store:)
      @project_store = project_store
      @chat_context_store = chat_context_store
    end

    def resolve(chat_id:, text:)
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

      Resolution.new(
        resolved: false,
        project_ref: nil,
        project_path: nil,
        workstream_id: nil,
        question: "No active project context found. Please specify a project id or alias."
      )
    end

    private

    def only_project
      projects = @project_store.list
      return nil unless projects.size == 1

      projects.first
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
  end
end
