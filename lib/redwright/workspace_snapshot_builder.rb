# frozen_string_literal: true

require "find"

module Redwright
  class WorkspaceSnapshotBuilder
    DEFAULT_MAX_TREE_ENTRIES = 120
    DEFAULT_MAX_SIGNIFICANT_FILES = 16
    DEFAULT_MAX_DEPTH = 3

    def build(project_path:, max_tree_entries: DEFAULT_MAX_TREE_ENTRIES, max_significant_files: DEFAULT_MAX_SIGNIFICANT_FILES, max_depth: DEFAULT_MAX_DEPTH)
      return "Workspace unavailable." unless project_path.is_a?(String) && !project_path.strip.empty? && Dir.exist?(project_path)

      tree_entries = collect_tree_entries(project_path, max_tree_entries: max_tree_entries, max_depth: max_depth)
      significant_files = collect_significant_files(project_path, max_significant_files: max_significant_files)

      lines = []
      lines << "Workspace root: #{project_path}"
      lines << "Tree (#{tree_entries.size} entries):"
      lines.concat(tree_entries.map { |entry| "- #{entry}" })
      lines << "Significant files (#{significant_files.size}):"
      lines.concat(significant_files.map { |file| "- #{file}" })
      lines.join("\n")
    rescue StandardError
      "Workspace snapshot unavailable."
    end

    private

    def collect_tree_entries(project_path, max_tree_entries:, max_depth:)
      entries = []
      Find.find(project_path) do |path|
        rel = relative_path(project_path, path)
        next if rel == "."
        if skip_path?(rel)
          Find.prune if File.directory?(path)
          next
        end

        depth = rel.count("/")
        if depth > max_depth
          Find.prune if File.directory?(path)
          next
        end

        entries << rel
        break if entries.size >= max_tree_entries
      end
      entries.sort
    end

    def collect_significant_files(project_path, max_significant_files:)
      preferred = %w[
        README.md
        AGENTS.md
        Gemfile
        Gemfile.lock
        Rakefile
        .redwright/manifest.yml
        lib/redwright.rb
        bin/redwright
      ]
      found = preferred.select { |rel| File.file?(File.join(project_path, rel)) }

      if found.size < max_significant_files
        ruby_files = Dir.glob(File.join(project_path, "{lib,test,bin}/**/*.{rb,md,yml,yaml}"), File::FNM_EXTGLOB)
                        .select { |path| File.file?(path) }
                        .map { |path| relative_path(project_path, path) }
                        .reject { |rel| skip_path?(rel) }
                        .sort
        found.concat(ruby_files)
      end

      found.uniq.first(max_significant_files)
    end

    def relative_path(root, path)
      rel = path.sub(%r{\A#{Regexp.escape(root)}/?}, "")
      rel.empty? ? "." : rel
    end

    def skip_path?(relative_path)
      relative_path.start_with?(".git", ".bundle", "vendor/bundle", "node_modules", "_workspace")
    end
  end
end
