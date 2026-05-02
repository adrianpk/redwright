# frozen_string_literal: true
require_relative "tree_sitter_structural_extractor"
require_relative "lsp_semantic_enricher"

module Redwright
  class IterationContextPacketBuilder
    DEFAULT_TOP_K_FILES = 5
    DEFAULT_SNIPPET_LINES = 24
    DEFAULT_MAX_TREE_ENTRIES = 64
    DEFAULT_MAX_SNIPPET_BYTES = 2000
    DEFAULT_MAX_PACKET_BYTES = 16_000
    MAX_TOP_K_FILES = 5
    MAX_SNIPPET_LINES = 40
    DEFAULT_TREE_VIEW = "top_level"
    DEFAULT_PARSER_MODE = "fallback_plain_text"
    DEFAULT_LSP_MODE = "fallback_disabled"

    def build(
      project_path:,
      task_goal:,
      current_errors:,
      previous_message:,
      active_clarification: nil,
      last_execution_results: [],
      normalized_failures: [],
      last_patch_summary: "",
      top_k_files: DEFAULT_TOP_K_FILES,
      snippet_lines: DEFAULT_SNIPPET_LINES,
      max_tree_entries: DEFAULT_MAX_TREE_ENTRIES,
      max_snippet_bytes: DEFAULT_MAX_SNIPPET_BYTES,
      max_packet_bytes: DEFAULT_MAX_PACKET_BYTES,
      tree_view: DEFAULT_TREE_VIEW,
      parser_mode: DEFAULT_PARSER_MODE,
      lsp_mode: DEFAULT_LSP_MODE
    )
      return fallback_packet(task_goal: task_goal, current_errors: current_errors, previous_message: previous_message) unless Dir.exist?(project_path.to_s)

      bounded_top_k = [[top_k_files.to_i, 1].max, MAX_TOP_K_FILES].min
      bounded_snippet_lines = [[snippet_lines.to_i, 1].max, MAX_SNIPPET_LINES].min

      files = significant_files(project_path: project_path, top_k_files: bounded_top_k)
      tree_entries = project_tree_snapshot(
        project_path: project_path,
        max_tree_entries: max_tree_entries,
        tree_view: tree_view
      )
      snippets = files.map do |rel_path|
        snippet = read_snippet(
          project_path: project_path,
          rel_path: rel_path,
          snippet_lines: bounded_snippet_lines,
          max_snippet_bytes: max_snippet_bytes
        )
        { path: rel_path, snippet: snippet }
      end

      semantic_capabilities = build_semantic_capabilities(parser_mode: parser_mode, lsp_mode: lsp_mode)
      current_file = snippets.first
      available_symbols = extract_available_symbols(
        project_path: project_path,
        snippets: snippets,
        parser_mode: semantic_capabilities[:parser_mode],
        lsp_mode: semantic_capabilities[:lsp_mode]
      )
      packet = {
        version: "v2",
        task_goal: task_goal.to_s,
        previous_message: previous_message.to_s,
        active_clarification: active_clarification.to_s,
        last_patch_summary: last_patch_summary.to_s,
        semantic_capabilities: semantic_capabilities,
        stack_hints: detect_stack_hints(project_path: project_path),
        errors: Array(current_errors).map(&:to_s),
        normalized_failures: Array(normalized_failures).map(&:to_s),
        last_execution_results: normalize_execution_results(last_execution_results),
        tree: {
          entries: tree_entries,
          total_entries: tree_entries.size
        },
        files: snippets,
        ir_v1: build_ir_v1(
          task_goal: task_goal,
          current_file: current_file,
          available_symbols: available_symbols,
          errors: Array(current_errors).map(&:to_s),
          tree_entries: tree_entries
        ),
        bounds: {
          top_k_files: bounded_top_k,
          snippet_lines: bounded_snippet_lines,
          max_tree_entries: max_tree_entries.to_i,
          max_snippet_bytes: max_snippet_bytes.to_i,
          max_packet_bytes: max_packet_bytes.to_i,
          tree_view: normalize_tree_view(tree_view)
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
      fallback_packet(
        task_goal: task_goal,
        current_errors: current_errors,
        previous_message: previous_message,
        active_clarification: active_clarification,
        last_execution_results: last_execution_results,
        normalized_failures: normalized_failures,
        last_patch_summary: last_patch_summary
      )
    end

    private

    def fallback_packet(
      task_goal:,
      current_errors:,
      previous_message:,
      active_clarification: nil,
      last_execution_results: [],
      normalized_failures: [],
      last_patch_summary: ""
    )
      packet = {
        version: "v2",
        task_goal: task_goal.to_s,
        previous_message: previous_message.to_s,
        active_clarification: active_clarification.to_s,
        last_patch_summary: last_patch_summary.to_s,
        semantic_capabilities: build_semantic_capabilities(
          parser_mode: DEFAULT_PARSER_MODE,
          lsp_mode: DEFAULT_LSP_MODE
        ),
        stack_hints: { ecosystem: "unknown", primary_language: "unknown", toolchains: [] },
        errors: Array(current_errors).map(&:to_s),
        normalized_failures: Array(normalized_failures).map(&:to_s),
        last_execution_results: normalize_execution_results(last_execution_results),
        tree: { entries: [], total_entries: 0 },
        files: [],
        ir_v1: build_ir_v1(
          task_goal: task_goal,
          current_file: nil,
          available_symbols: [],
          errors: Array(current_errors).map(&:to_s),
          tree_entries: []
        ),
        bounds: {
          top_k_files: 0,
          snippet_lines: DEFAULT_SNIPPET_LINES,
          max_tree_entries: DEFAULT_MAX_TREE_ENTRIES,
          max_snippet_bytes: DEFAULT_MAX_SNIPPET_BYTES,
          max_packet_bytes: DEFAULT_MAX_PACKET_BYTES,
          tree_view: DEFAULT_TREE_VIEW
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

    def project_tree_snapshot(project_path:, max_tree_entries:, tree_view: DEFAULT_TREE_VIEW)
      normalized_view = normalize_tree_view(tree_view)
      return project_tree_top_level_snapshot(project_path: project_path, max_tree_entries: max_tree_entries) if normalized_view == "top_level"

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

    def project_tree_top_level_snapshot(project_path:, max_tree_entries:)
      entries = []
      Dir.children(project_path).sort.each do |entry|
        next if entry.start_with?(".") || entry == "_workspace"

        full = File.join(project_path, entry)
        marker = File.directory?(full) ? "#{entry}/" : entry
        next if skip_path?(marker)

        entries << marker
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
      lines << "- active_clarification: #{packet[:active_clarification]}"
      lines << "- last_patch_summary: #{packet[:last_patch_summary]}"
      lines << "- semantic_capabilities:"
      packet[:semantic_capabilities].each { |k, v| lines << "  - #{k}: #{v}" }
      lines << "- stack_hints:"
      lines << "  - ecosystem: #{packet.dig(:stack_hints, :ecosystem)}"
      lines << "  - primary_language: #{packet.dig(:stack_hints, :primary_language)}"
      lines << "  - toolchains: #{Array(packet.dig(:stack_hints, :toolchains)).join(', ')}"
      lines << "- errors:"
      packet[:errors].each { |err| lines << "  - #{err}" }
      lines << "- normalized_failures:"
      packet[:normalized_failures].each { |failure| lines << "  - #{failure}" }
      lines << "- last_execution_results:"
      packet[:last_execution_results].each do |result|
        lines << "  - command: #{result[:command]}"
        lines << "    status: #{result[:status]}"
        lines << "    exit_code: #{result[:exit_code]}"
        lines << "    summary: #{result[:summary]}"
      end
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
      lines << "- ir_v1_sections:"
      packet.fetch(:ir_v1, {}).each_key { |section| lines << "  - #{section}" }
      lines.join("\n")
    end

    def build_semantic_capabilities(parser_mode:, lsp_mode:)
      normalized_parser_mode = normalize_parser_mode(parser_mode)
      normalized_lsp_mode = normalize_lsp_mode(lsp_mode)
      {
        parser_mode: normalized_parser_mode,
        lsp_mode: normalized_lsp_mode,
        parser_preferred: normalized_parser_mode.start_with?("preferred_"),
        lsp_preferred: normalized_lsp_mode.start_with?("preferred_")
      }
    end

    def build_ir_v1(task_goal:, current_file:, available_symbols:, errors:, tree_entries:)
      {
        "TASK" => {
          "goal" => task_goal.to_s
        },
        "CURRENT_FILE" => {
          "path" => current_file ? current_file[:path].to_s : "",
          "snippet" => current_file ? current_file[:snippet].to_s : ""
        },
        "AVAILABLE_SYMBOLS" => Array(available_symbols),
        "DOC_HINTS" => [],
        "ERRORS" => Array(errors).map(&:to_s),
        "REPO_MAP" => Array(tree_entries).map(&:to_s)
      }
    end

    def extract_available_symbols(project_path:, snippets:, parser_mode:, lsp_mode:)
      return [] unless parser_mode == "preferred_tree_sitter"

      extractor = TreeSitterStructuralExtractor.new
      symbols = snippets.flat_map do |entry|
        extractor.extract(project_path: project_path, rel_path: entry[:path])
      end
      sorted = symbols.sort_by { |item| [item[:path].to_s, item[:line].to_i, item[:kind].to_s, item[:name].to_s] }
      return sorted unless lsp_mode == "preferred_lsp"

      LspSemanticEnricher.new.enrich(symbols: sorted)
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

    def normalize_execution_results(results)
      Array(results).map do |entry|
        hash = entry.is_a?(Hash) ? entry : {}
        {
          command: hash[:command].to_s,
          status: hash[:status].to_s,
          exit_code: hash[:exit_code].to_s,
          summary: hash[:summary].to_s
        }
      end
    end

    def normalize_tree_view(tree_view)
      value = tree_view.to_s.strip
      return DEFAULT_TREE_VIEW if value.empty?
      return "top_level" if value == "top_level"
      return "recursive" if value == "recursive"

      DEFAULT_TREE_VIEW
    end

    def normalize_parser_mode(parser_mode)
      value = parser_mode.to_s.strip
      return "preferred_tree_sitter" if value == "preferred_tree_sitter"
      return "fallback_plain_text" if value == "fallback_plain_text"

      DEFAULT_PARSER_MODE
    end

    def normalize_lsp_mode(lsp_mode)
      value = lsp_mode.to_s.strip
      return "preferred_lsp" if value == "preferred_lsp"
      return "fallback_disabled" if value == "fallback_disabled"

      DEFAULT_LSP_MODE
    end

    def detect_stack_hints(project_path:)
      if File.file?(File.join(project_path, "go.mod"))
        return {
          ecosystem: "go",
          primary_language: "go",
          toolchains: ["go test", "go vet"]
        }
      end

      if File.file?(File.join(project_path, "Gemfile"))
        return {
          ecosystem: "ruby",
          primary_language: "ruby",
          toolchains: ["bundle exec rake", "bundle exec ruby -Itest"]
        }
      end

      if File.file?(File.join(project_path, "package.json"))
        return {
          ecosystem: "node",
          primary_language: "javascript",
          toolchains: ["npm test", "npm run lint"]
        }
      end

      {
        ecosystem: "unknown",
        primary_language: "unknown",
        toolchains: []
      }
    end
  end
end
