# frozen_string_literal: true

module Redwright
  class IterationContextPacketBuilder
    DEFAULT_TOP_K_FILES = 5
    DEFAULT_SNIPPET_LINES = 24

    def build(project_path:, task_goal:, current_errors:, previous_message:, top_k_files: DEFAULT_TOP_K_FILES, snippet_lines: DEFAULT_SNIPPET_LINES)
      return fallback_packet(task_goal: task_goal, current_errors: current_errors, previous_message: previous_message) unless Dir.exist?(project_path.to_s)

      files = significant_files(project_path: project_path, top_k_files: top_k_files)
      snippets = files.map do |rel_path|
        [rel_path, read_snippet(project_path: project_path, rel_path: rel_path, snippet_lines: snippet_lines)]
      end

      prompt = []
      prompt << "Context packet (bounded):"
      prompt << "- task_goal: #{task_goal}"
      prompt << "- previous_message: #{previous_message}"
      prompt << "- top_files_count: #{files.size}"
      prompt << "- errors:"
      current_errors.each { |err| prompt << "  - #{err}" }
      prompt << "- top_files:"
      files.each { |file| prompt << "  - #{file}" }
      prompt << "- snippets:"
      snippets.each do |rel_path, snippet|
        prompt << "  - file: #{rel_path}"
        prompt << "    content: |"
        snippet.each_line { |line| prompt << "      #{line.rstrip}" }
      end

      {
        prompt_text: prompt.join("\n"),
        summary: {
          top_files_count: files.size,
          top_files: files
        }
      }
    rescue StandardError
      fallback_packet(task_goal: task_goal, current_errors: current_errors, previous_message: previous_message)
    end

    private

    def fallback_packet(task_goal:, current_errors:, previous_message:)
      {
        prompt_text: [
          "Context packet (bounded):",
          "- task_goal: #{task_goal}",
          "- previous_message: #{previous_message}",
          "- top_files_count: 0",
          "- errors:",
          *current_errors.map { |e| "  - #{e}" }
        ].join("\n"),
        summary: { top_files_count: 0, top_files: [] }
      }
    end

    def significant_files(project_path:, top_k_files:)
      preferred = %w[
        README.md
        AGENTS.md
        Gemfile
        Rakefile
        .redwright/manifest.yml
      ]
      found = preferred.select { |rel| File.file?(File.join(project_path, rel)) }
      if found.size < top_k_files
        ruby_files = Dir.glob(File.join(project_path, "{lib,test,bin}/**/*.{rb,md,yml,yaml}"), File::FNM_EXTGLOB)
                        .select { |path| File.file?(path) }
                        .map { |path| relative_path(project_path, path) }
                        .reject { |rel| skip_path?(rel) }
                        .sort
        found.concat(ruby_files)
      end
      found.uniq.first(top_k_files)
    end

    def read_snippet(project_path:, rel_path:, snippet_lines:)
      full = File.join(project_path, rel_path)
      return "" unless File.file?(full)

      File.readlines(full).first(snippet_lines).join
    end

    def relative_path(root, path)
      path.sub(%r{\A#{Regexp.escape(root)}/?}, "")
    end

    def skip_path?(relative_path)
      relative_path.start_with?(".git", ".bundle", "vendor/bundle", "node_modules", "_workspace")
    end
  end
end
