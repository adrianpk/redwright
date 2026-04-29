# frozen_string_literal: true

require "yaml"
require_relative "workspace_snapshot_builder"
require_relative "project_manifest"

module Redwright
  class PromptContextLoader
    def initialize(repo_root: Dir.pwd, workspace_snapshot_builder: WorkspaceSnapshotBuilder.new, project_manifest: ProjectManifest.new)
      @repo_root = repo_root
      @workspace_snapshot_builder = workspace_snapshot_builder
      @project_manifest = project_manifest
    end

    def build(project_path:)
      manifest = load_manifest(project_path)
      {
        project_context: project_context_from_manifest(manifest, project_path) || project_context_from_fallback(project_path),
        architecture_context: architecture_context_from_manifest(manifest) || architecture_context_from_fallback,
        quality: quality_from_manifest(manifest),
        workspace_context: workspace_context(project_path)
      }
    end

    private

    def load_manifest(project_path)
      return {} unless project_path.is_a?(String) && !project_path.strip.empty?

      path = File.join(project_path, ".redwright", "manifest.yml")
      return {} unless File.file?(path)

      result = @project_manifest.load(path)
      result.valid? ? result.data : {}
    rescue StandardError
      {}
    end

    def project_context_from_manifest(manifest, project_path)
      lines = []
      project = manifest["project"].is_a?(Hash) ? manifest["project"] : {}
      lines << "Project name: #{project['name']}" if non_empty_string?(project["name"])
      lines << "Stack: #{project['stack']}" if non_empty_string?(project["stack"])
      lines << "Project summary: #{project['summary']}" if non_empty_string?(project["summary"])
      context = manifest["context"].is_a?(Hash) ? manifest["context"] : {}
      lines << "Project context: #{context['project']}" if non_empty_string?(context["project"])
      return nil if lines.empty?

      lines.join("\n")
    end

    def architecture_context_from_manifest(manifest)
      lines = []
      architecture = manifest["architecture"].is_a?(Hash) ? manifest["architecture"] : {}
      lines << architecture["context"] if non_empty_string?(architecture["context"])

      conventions = architecture["conventions"]
      conventions = manifest["conventions"] if conventions.nil?
      normalized = normalize_list(conventions)
      lines << "Conventions: #{normalized.join(' | ')}" unless normalized.empty?

      quality = manifest["quality"].is_a?(Hash) ? manifest["quality"] : {}
      lines << "Lint command: #{quality['lint_command']}" if non_empty_string?(quality["lint_command"])
      lines << "Test command: #{quality['test_command']}" if non_empty_string?(quality["test_command"])
      return nil if lines.empty?

      lines.join("\n")
    end

    def project_context_from_fallback(project_path)
      "Project path: #{project_path}\nProject context source: AGENTS.md fallback"
    end

    def architecture_context_from_fallback
      agents_path = File.join(@repo_root, "AGENTS.md")
      lines = []
      lines.concat(extract_policy_lines(File.read(agents_path), 8)) if File.file?(agents_path)
      referenced_agent_files(agents_path).each do |rel|
        path = File.join(@repo_root, rel)
        next unless File.file?(path)

        lines.concat(extract_policy_lines(File.read(path), 6))
      end
      lines = lines.uniq.first(14)
      return "Use repository AGENTS policies and conventions." if lines.empty?

      "Fallback conventions and guardrails:\n- #{lines.join("\n- ")}"
    end

    def referenced_agent_files(agents_path)
      return [] unless File.file?(agents_path)

      File.readlines(agents_path)
          .filter_map { |line| line[/`(\.agents\/[^`]+)`/, 1] }
          .uniq
    end

    def extract_policy_lines(content, limit)
      content.to_s.lines
             .map(&:strip)
             .reject(&:empty?)
             .reject { |line| line.start_with?("#") }
             .select { |line| policy_line?(line) }
             .first(limit)
    end

    def policy_line?(line)
      text = line.downcase
      text.include?("must") ||
        text.include?("never") ||
        text.include?("always") ||
        text.include?("do not") ||
        text.include?("rules") ||
        text.include?("convention") ||
        text.include?("lint")
    end

    def normalize_list(value)
      return [] unless value.is_a?(Array)

      value.select { |entry| non_empty_string?(entry) }.map(&:strip)
    end

    def non_empty_string?(value)
      value.is_a?(String) && !value.strip.empty?
    end

    def quality_from_manifest(manifest)
      quality = manifest["quality"]
      return { auto_validate: false, lint_command: nil, test_command: nil } unless quality.is_a?(Hash)

      {
        auto_validate: quality["auto_validate"] == true,
        lint_command: string_or_nil(quality["lint_command"]),
        test_command: string_or_nil(quality["test_command"])
      }
    end

    def string_or_nil(value)
      return nil unless non_empty_string?(value)

      value.strip
    end

    def workspace_context(project_path)
      @workspace_snapshot_builder.build(project_path: project_path)
    rescue StandardError
      "Workspace snapshot unavailable."
    end
  end
end
