# frozen_string_literal: true

module Redwright
  class IterationContextPacketBuilder
    DEFAULT_TOP_K_FILES = 5
    DEFAULT_SNIPPET_LINES = 24
    DEFAULT_MAX_TREE_ENTRIES = 64
    DEFAULT_MAX_SNIPPET_BYTES = 2000
    DEFAULT_MAX_PACKET_BYTES = 16_000

    def build(
      project_path:,
      task_goal:,
      current_errors:,
      previous_message:,
      top_k_files: DEFAULT_TOP_K_FILES,
      snippet_lines: DEFAULT_SNIPPET_LINES,
      max_tree_entries: DEFAULT_MAX_TREE_ENTRIES,
      max_snippet_bytes: DEFAULT_MAX_SNIPPET_BYTES,
      max_packet_bytes: DEFAULT_MAX_PACKET_BYTES
    )
      return fallback_packet(task_goal: task_goal, current_errors: current_errors, previous_message: previous_message) unless Dir.exist?(project_path.to_s)

      files = significant_files(project_path: project_path, top_k_files: top_k_files)
      tree_entries = project_tree_snapshot(project_path: project_path, max_tree_entries: max_tree_entries)
      snippets = files.map do |rel_path|
        snippet = read_snippet(
          project_path: project_path,
          rel_path: rel_path,
          snippet_lines: snippet_lines,
          max_snippet_bytes: max_snippet_bytes
        )
        { path: rel_path, snippet: snippet }
      end

      packet = {
        version: "v2",
        task_goal: task_goal.to_s,
        previous_message: previous_message.to_s,
        errors: Array(current_errors).map(&:to_s),
        tree: {
          entries: tree_entries,
          total_entries: tree_entries.size
        },
        files: snippets,
        bounds: {
          top_k_files: top_k_files.to_i,
          snippet_lines: snippet_lines.to_i,
          max_tree_entries: max_tree_entries.to_i,
          max_snippet_bytes: max_snippet_bytes.to_i,
          max_packet_bytes: max_packet_bytes.to_i
        }
      }
      prompt = serialize_packet(packet)
      if prompt.bytesize > max_packet_bytes.to_i
        packet = trim_packet(packet: packet, max_packet_bytes: max_packet_bytes.to_i)
        prompt = serialize_packet(packet)
      end

      {
        packet: packet,
        prompt_text: prompt,
        summary: {
          top_files_count: files.size,
          top_files: files,
          tree_entries_count: packet.dig(:tree, :entries).size,
          packet_bytes: prompt.bytesize
        }
      }
    rescue StandardError
      fallback_packet(task_goal: task_goal, current_errors: current_errors, previous_message: previous_message)
    end

    private

    def fallback_packet(task_goal:, current_errors:, previous_message:)
      packet = {
        version: "v2",
        task_goal: task_goal.to_s,
        previous_message: previous_message.to_s,
        errors: Array(current_errors).map(&:to_s),
        tree: { entries: [], total_entries: 0 },
        files: [],
        bounds: {
          top_k_files: 0,
          snippet_lines: DEFAULT_SNIPPET_LINES,
          max_tree_entries: DEFAULT_MAX_TREE_ENTRIES,
          max_snippet_bytes: DEFAULT_MAX_SNIPPET_BYTES,
          max_packet_bytes: DEFAULT_MAX_PACKET_BYTES
        }
      }
      {
        packet: packet,
        prompt_text: serialize_packet(packet),
        summary: { top_files_count: 0, top_files: [], tree_entries_count: 0, packet_bytes: 0 }
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

    def read_snippet(project_path:, rel_path:, snippet_lines:, max_snippet_bytes:)
      full = File.join(project_path, rel_path)
      return "" unless File.file?(full)

      text = File.readlines(full).first(snippet_lines).join
      return text if text.bytesize <= max_snippet_bytes.to_i

      text.byteslice(0, max_snippet_bytes.to_i) + "\n...[truncated]"
    end

    def relative_path(root, path)
      path.sub(%r{\A#{Regexp.escape(root)}/?}, "")
    end

    def skip_path?(relative_path)
      relative_path.start_with?(".git", ".bundle", "vendor/bundle", "node_modules", "_workspace")
    end

    def project_tree_snapshot(project_path:, max_tree_entries:)
      entries = []
      Dir.glob(File.join(project_path, "**/*"), File::FNM_DOTMATCH).sort.each do |path|
        next if File.directory?(path)

        rel = relative_path(project_path, path)
        next if rel.empty? || skip_path?(rel)

        entries << rel
        break if entries.size >= max_tree_entries.to_i
      end
      entries
    end

    def serialize_packet(packet)
      lines = []
      lines << "Semantic Context Packet v2"
      lines << "- version: #{packet[:version]}"
      lines << "- task_goal: #{packet[:task_goal]}"
      lines << "- previous_message: #{packet[:previous_message]}"
      lines << "- errors:"
      packet[:errors].each { |err| lines << "  - #{err}" }
      lines << "- tree_entries_count: #{packet.dig(:tree, :entries).size}"
      lines << "- tree_entries:"
      packet.dig(:tree, :entries).each { |entry| lines << "  - #{entry}" }
      lines << "- selected_files_count: #{packet[:files].size}"
      lines << "- selected_files:"
      packet[:files].each do |file|
        lines << "  - file: #{file[:path]}"
        lines << "    content: |"
        file[:snippet].to_s.each_line { |line| lines << "      #{line.rstrip}" }
      end
      lines << "- bounds:"
      packet[:bounds].each { |k, v| lines << "  - #{k}: #{v}" }
      lines.join("\n")
    end

    def trim_packet(packet:, max_packet_bytes:)
      trimmed = Marshal.load(Marshal.dump(packet))
      while serialize_packet(trimmed).bytesize > max_packet_bytes
        if trimmed[:files].size > 1
          trimmed[:files].pop
          next
        end
        if trimmed.dig(:tree, :entries).size > 1
          trimmed[:tree][:entries].pop
          next
        end
        break
      end
      trimmed
    end
  end
end
