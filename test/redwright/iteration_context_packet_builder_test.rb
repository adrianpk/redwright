# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/iteration_context_packet_builder"

class IterationContextPacketBuilderTest < Minitest::Test
  def test_build_limits_top_files_and_includes_snippets
    Dir.mktmpdir("redwright-iter-packet-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "README.md"), "# demo\n")
      File.write(File.join(dir, "lib", "a.rb"), "class A\nend\n")
      File.write(File.join(dir, "lib", "b.rb"), "class B\nend\n")
      File.write(File.join(dir, "lib", "c.rb"), "class C\nend\n")

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "fix failing test",
        previous_message: "update parser",
        current_errors: ["Validation failed", "Failed checks: test"],
        active_clarification: "Need project name",
        normalized_failures: ["test_failure"],
        last_execution_results: [
          { command: "bundle exec ruby -Itest test/x_test.rb", status: "error", exit_code: 1, summary: "1 failing test" }
        ],
        last_patch_summary: "Updated parser normalization branch",
        top_k_files: 2
      )

      assert_equal(2, packet[:summary][:top_files_count])
      assert_equal(2, packet[:summary][:top_files].size)
      assert_equal("v2", packet.dig(:packet, :version))
      assert_equal("unknown", packet.dig(:packet, :stack_hints, :ecosystem))
      assert_includes(packet[:prompt_text], "Semantic Context Packet v2")
      assert_includes(packet[:prompt_text], "task_goal: fix failing test")
      assert_includes(packet[:prompt_text], "active_clarification: Need project name")
      assert_includes(packet[:prompt_text], "last_patch_summary: Updated parser normalization branch")
      assert_includes(packet[:prompt_text], "normalized_failures:")
      assert_includes(packet[:prompt_text], "last_execution_results:")
      assert_includes(packet[:prompt_text], "bundle exec ruby -Itest test/x_test.rb")
      assert_includes(packet[:prompt_text], "content: |")
      assert_operator(packet[:summary][:packet_bytes], :>, 0)
    end
  end

  def test_build_enforces_hard_top_k_cap
    Dir.mktmpdir("redwright-iter-packet-topk-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      12.times do |idx|
        File.write(File.join(dir, "lib", "f#{idx}.rb"), "class F#{idx}\nend\n")
      end

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "implement feature",
        previous_message: "initial",
        current_errors: [],
        top_k_files: 99
      )

      assert_operator(packet[:summary][:top_files_count], :<=, 5)
      assert_equal(5, packet.dig(:packet, :bounds, :top_k_files))
    end
  end

  def test_build_applies_bounded_packet_size
    Dir.mktmpdir("redwright-iter-packet-bounds-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      5.times do |idx|
        File.write(File.join(dir, "lib", "f#{idx}.rb"), ("line\n" * 200))
      end

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "fix",
        previous_message: "retry",
        current_errors: ["Validation failed"],
        top_k_files: 5,
        max_tree_entries: 5,
        max_snippet_bytes: 400,
        max_packet_bytes: 1500
      )

      assert_operator(packet[:prompt_text].bytesize, :<=, 1500)
      assert_operator(packet.dig(:packet, :files).size, :<=, 5)
      assert_operator(packet.dig(:packet, :tree, :entries).size, :<=, 5)
    end
  end

  def test_trim_order_is_deterministic_files_then_tree
    Dir.mktmpdir("redwright-iter-packet-trim-order-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "README.md"), "# demo\n")
      6.times do |idx|
        File.write(File.join(dir, "lib", "f#{idx}.rb"), ("line #{idx}\n" * 200))
      end

      builder = Redwright::IterationContextPacketBuilder.new
      baseline = builder.build(
        project_path: dir,
        task_goal: "trim test",
        previous_message: "prev",
        current_errors: ["Validation failed", "lint failed", "test failed"],
        top_k_files: 5,
        max_tree_entries: 20,
        max_snippet_bytes: 1500,
        max_packet_bytes: 50_000
      )
      packet = builder.build(
        project_path: dir,
        task_goal: "trim test",
        previous_message: "prev",
        current_errors: ["Validation failed", "lint failed", "test failed"],
        top_k_files: 5,
        max_tree_entries: 20,
        max_snippet_bytes: 1500,
        max_packet_bytes: 1200
      )

      baseline_files = baseline.dig(:packet, :files).size
      baseline_tree = baseline.dig(:packet, :tree, :entries).size
      trimmed_files = packet.dig(:packet, :files).size
      trimmed_tree = packet.dig(:packet, :tree, :entries).size

      assert_operator(trimmed_files, :<=, baseline_files)
      assert_operator(trimmed_tree, :<=, baseline_tree)
      if trimmed_tree < baseline_tree
        assert_equal(1, trimmed_files)
      end
      assert_operator(packet[:prompt_text].bytesize, :<=, 1200)
    end
  end

  def test_build_uses_top_level_tree_by_default
    Dir.mktmpdir("redwright-iter-packet-tree-top-level-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib", "nested"))
      FileUtils.mkdir_p(File.join(dir, "test"))
      File.write(File.join(dir, "README.md"), "# demo\n")
      File.write(File.join(dir, "lib", "nested", "deep.rb"), "class Deep\nend\n")

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "fix",
        previous_message: "retry",
        current_errors: []
      )

      tree = packet.dig(:packet, :tree, :entries)
      assert_includes(tree, "lib/")
      assert_includes(tree, "test/")
      assert_includes(tree, "README.md")
      refute(tree.any? { |e| e.include?("/") && e != "lib/" && e != "test/" })
      assert_equal("top_level", packet.dig(:packet, :bounds, :tree_view))
    end
  end

  def test_build_supports_recursive_tree_view_when_explicitly_requested
    Dir.mktmpdir("redwright-iter-packet-tree-recursive-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib", "nested"))
      File.write(File.join(dir, "lib", "nested", "deep.rb"), "class Deep\nend\n")

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "fix",
        previous_message: "retry",
        current_errors: [],
        tree_view: "recursive"
      )

      tree = packet.dig(:packet, :tree, :entries)
      assert_includes(tree, "lib/nested/deep.rb")
      assert_equal("recursive", packet.dig(:packet, :bounds, :tree_view))
    end
  end

  def test_detects_go_stack_hints
    Dir.mktmpdir("redwright-iter-packet-go-") do |dir|
      File.write(File.join(dir, "go.mod"), "module example.com/x\n\ngo 1.22\n")
      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "build go app",
        previous_message: "none",
        current_errors: []
      )
      assert_equal("go", packet.dig(:packet, :stack_hints, :ecosystem))
      assert_equal("go", packet.dig(:packet, :stack_hints, :primary_language))
      assert_includes(packet.dig(:packet, :stack_hints, :toolchains), "go test")
    end
  end

  def test_detects_ruby_stack_hints
    Dir.mktmpdir("redwright-iter-packet-ruby-") do |dir|
      File.write(File.join(dir, "Gemfile"), "source 'https://rubygems.org'\n")
      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "build ruby app",
        previous_message: "none",
        current_errors: []
      )
      assert_equal("ruby", packet.dig(:packet, :stack_hints, :ecosystem))
      assert_equal("ruby", packet.dig(:packet, :stack_hints, :primary_language))
      assert_includes(packet.dig(:packet, :stack_hints, :toolchains), "bundle exec rake")
    end
  end

  def test_detects_node_stack_hints
    Dir.mktmpdir("redwright-iter-packet-node-") do |dir|
      File.write(File.join(dir, "package.json"), "{\"name\":\"x\"}\n")
      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "build node app",
        previous_message: "none",
        current_errors: []
      )
      assert_equal("node", packet.dig(:packet, :stack_hints, :ecosystem))
      assert_equal("javascript", packet.dig(:packet, :stack_hints, :primary_language))
      assert_includes(packet.dig(:packet, :stack_hints, :toolchains), "npm test")
    end
  end

  def test_prefers_manifest_in_selected_files_when_present
    Dir.mktmpdir("redwright-iter-packet-manifest-") do |dir|
      FileUtils.mkdir_p(File.join(dir, ".redwright"))
      File.write(File.join(dir, ".redwright", "manifest.yml"), "schema_version: 1\n")
      File.write(File.join(dir, "README.md"), "# demo\n")
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "lib", "main.rb"), "class Main\nend\n")

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "use manifest context",
        previous_message: "none",
        current_errors: [],
        top_k_files: 5
      )

      selected = packet[:summary][:top_files]
      assert_includes(selected, ".redwright/manifest.yml")
    end
  end

  def test_emits_semantic_capabilities_with_preferred_and_fallback_states
    Dir.mktmpdir("redwright-iter-packet-capabilities-") do |dir|
      File.write(File.join(dir, "README.md"), "# demo\n")

      preferred = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "semantic preferred",
        previous_message: "none",
        current_errors: [],
        parser_mode: "preferred_tree_sitter",
        lsp_mode: "preferred_lsp"
      )
      fallback = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "semantic fallback",
        previous_message: "none",
        current_errors: []
      )

      assert_equal("preferred_tree_sitter", preferred.dig(:packet, :semantic_capabilities, :parser_mode))
      assert_equal("preferred_lsp", preferred.dig(:packet, :semantic_capabilities, :lsp_mode))
      assert_equal(true, preferred.dig(:packet, :semantic_capabilities, :parser_preferred))
      assert_equal(true, preferred.dig(:packet, :semantic_capabilities, :lsp_preferred))

      assert_equal("fallback_plain_text", fallback.dig(:packet, :semantic_capabilities, :parser_mode))
      assert_equal("fallback_disabled", fallback.dig(:packet, :semantic_capabilities, :lsp_mode))
      assert_equal(false, fallback.dig(:packet, :semantic_capabilities, :parser_preferred))
      assert_equal(false, fallback.dig(:packet, :semantic_capabilities, :lsp_preferred))
    end
  end

  def test_emits_stable_ir_v1_schema_and_ordering
    Dir.mktmpdir("redwright-iter-packet-irv1-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "README.md"), "# demo\n")
      File.write(File.join(dir, "lib", "alpha.rb"), "class Alpha\nend\n")

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "stabilize ir",
        previous_message: "prev",
        current_errors: ["Validation failed"],
        top_k_files: 3
      )

      ir = packet.dig(:packet, :ir_v1)
      assert_equal(%w[TASK CURRENT_FILE AVAILABLE_SYMBOLS DOC_HINTS ERRORS REPO_MAP], ir.keys)
      assert_equal("stabilize ir", ir.dig("TASK", "goal"))
      assert_equal(packet.dig(:packet, :files, 0, :path).to_s, ir.dig("CURRENT_FILE", "path"))
      assert_equal(["Validation failed"], ir["ERRORS"])
      assert_equal(packet.dig(:packet, :tree, :entries), ir["REPO_MAP"])
    end
  end

  def test_populates_available_symbols_with_tree_sitter_mode
    Dir.mktmpdir("redwright-iter-packet-symbols-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(
        File.join(dir, "lib", "sample.rb"),
        <<~RUBY
          require "json"
          class Parser
            def parse(input)
            end
          end
        RUBY
      )

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "extract symbols",
        previous_message: "none",
        current_errors: [],
        parser_mode: "preferred_tree_sitter",
        top_k_files: 3
      )

      symbols = packet.dig(:packet, :ir_v1, "AVAILABLE_SYMBOLS")
      assert(symbols.any? { |s| s[:kind] == "import" && s[:name] == "json" })
      assert(symbols.any? { |s| s[:kind] == "signature" && s[:name] == "parse" })
      assert(symbols.any? { |s| s[:kind] == "type" && s[:name] == "Parser" })
    end
  end

  def test_enriches_available_symbols_when_lsp_mode_is_preferred
    Dir.mktmpdir("redwright-iter-packet-lsp-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(
        File.join(dir, "lib", "a.rb"),
        <<~RUBY
          class Parser
            def parse(input)
            end
          end
        RUBY
      )
      File.write(
        File.join(dir, "lib", "b.rb"),
        <<~RUBY
          class Parser
            def parse(payload)
            end
          end
        RUBY
      )

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "enrich symbols",
        previous_message: "none",
        current_errors: [],
        parser_mode: "preferred_tree_sitter",
        lsp_mode: "preferred_lsp",
        top_k_files: 5
      )

      symbols = packet.dig(:packet, :ir_v1, "AVAILABLE_SYMBOLS")
      assert(symbols.any? { |s| s.key?(:lsp_edges) && !s[:lsp_edges].empty? })
    end
  end

  def test_does_not_enrich_symbols_when_lsp_mode_is_fallback
    Dir.mktmpdir("redwright-iter-packet-no-lsp-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "lib", "sample.rb"), "class Parser\n  def parse(input)\n  end\nend\n")

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "no lsp",
        previous_message: "none",
        current_errors: [],
        parser_mode: "preferred_tree_sitter",
        lsp_mode: "fallback_disabled"
      )

      symbols = packet.dig(:packet, :ir_v1, "AVAILABLE_SYMBOLS")
      refute(symbols.any? { |s| s.key?(:lsp_edges) })
    end
  end

  def test_uses_plain_text_fallback_extractor_when_parser_mode_is_fallback
    Dir.mktmpdir("redwright-iter-packet-fallback-parser-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(
        File.join(dir, "lib", "sample.rb"),
        <<~RUBY
          require "json"
          class Parser
            def parse(input)
            end
          end
        RUBY
      )

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "fallback parser symbols",
        previous_message: "none",
        current_errors: [],
        parser_mode: "fallback_plain_text",
        lsp_mode: "fallback_disabled"
      )

      symbols = packet.dig(:packet, :ir_v1, "AVAILABLE_SYMBOLS")
      assert(symbols.any? { |s| s[:kind] == "import" && s[:name] == "json" })
      assert(symbols.any? { |s| s[:kind] == "signature" && s[:name] == "parse" })
      assert(symbols.any? { |s| s[:kind] == "type" && s[:name] == "Parser" })
    end
  end

  def test_ir_schema_parity_between_preferred_and_fallback_parser_modes
    Dir.mktmpdir("redwright-iter-packet-parser-parity-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "lib", "sample.rb"), "class Parser\n  def parse(input)\n  end\nend\n")

      preferred = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "preferred",
        previous_message: "none",
        current_errors: [],
        parser_mode: "preferred_tree_sitter",
        lsp_mode: "fallback_disabled"
      )
      fallback = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "fallback",
        previous_message: "none",
        current_errors: [],
        parser_mode: "fallback_plain_text",
        lsp_mode: "fallback_disabled"
      )

      assert_equal(preferred.dig(:packet, :ir_v1).keys, fallback.dig(:packet, :ir_v1).keys)
      assert_equal("preferred_tree_sitter", preferred.dig(:packet, :semantic_capabilities, :parser_mode))
      assert_equal("fallback_plain_text", fallback.dig(:packet, :semantic_capabilities, :parser_mode))
      assert_equal(false, preferred.dig(:packet, :semantic_capabilities, :lsp_preferred))
      assert_equal(false, fallback.dig(:packet, :semantic_capabilities, :lsp_preferred))
    end
  end

  def test_layered_selection_prioritizes_current_file_then_dependencies
    Dir.mktmpdir("redwright-layered-selection-priority-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(
        File.join(dir, "lib", "a.rb"),
        <<~RUBY
          class Parser
            def parse(input)
            end
          end
        RUBY
      )
      File.write(
        File.join(dir, "lib", "b.rb"),
        <<~RUBY
          class Parser
            def parse(payload)
            end
          end
        RUBY
      )
      File.write(
        File.join(dir, "lib", "c.rb"),
        <<~RUBY
          class Parser
            def parse(data)
            end
          end
        RUBY
      )

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "fix parse flow",
        previous_message: "none",
        current_errors: [],
        parser_mode: "preferred_tree_sitter",
        lsp_mode: "preferred_lsp",
        top_k_files: 5
      )

      symbols = packet.dig(:packet, :ir_v1, "AVAILABLE_SYMBOLS")
      current_file_path = packet.dig(:packet, :ir_v1, "CURRENT_FILE", "path")
      current_file_symbols = symbols.select { |s| s[:layer] == "CURRENT_FILE" }
      dependency_symbols = symbols.select { |s| s[:layer] == "DEPENDENCIES" }

      assert(current_file_symbols.all? { |s| s[:path] == current_file_path })
      assert(packet.dig(:packet, :layered_selection, :dependency_symbols_count) <= 6)
      assert(dependency_symbols.none? { |s| s[:path] == current_file_path })
    end
  end

  def test_layered_selection_enforces_global_signal_bound
    Dir.mktmpdir("redwright-layered-selection-bounds-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      12.times do |idx|
        File.write(
          File.join(dir, "lib", "f#{idx}.rb"),
          "class Parser#{idx}\n  def parse_#{idx}(input)\n  end\nend\n"
        )
      end

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "optimize parser",
        previous_message: "none",
        current_errors: [],
        parser_mode: "preferred_tree_sitter",
        lsp_mode: "fallback_disabled",
        top_k_files: 5
      )

      assert(packet.dig(:packet, :layered_selection, :global_signal_symbols_count) <= 4)
      assert(packet.dig(:packet, :layered_selection, :total_selected_symbols) <= (8 + 6 + 4))
    end
  end

  def test_doc_hints_are_compact_and_normalized
    Dir.mktmpdir("redwright-doc-hints-compact-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(
        File.join(dir, "README.md"),
        <<~MD
          # Parse Pipeline
          -   parse payload into normalized tokens for runtime selection and stable replay with explicit contracts
          > keep deterministic ordering for semantic context
        MD
      )
      File.write(File.join(dir, "lib", "sample.rb"), "class Sample\n  def parse_payload(input)\n  end\nend\n")

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "improve parser context",
        previous_message: "none",
        current_errors: [],
        parser_mode: "preferred_tree_sitter",
        top_k_files: 5
      )

      doc_hints = packet.dig(:packet, :ir_v1, "DOC_HINTS")
      assert_operator(doc_hints.size, :>, 0)
      assert(doc_hints.all? { |hint| hint[:text].is_a?(String) && !hint[:text].empty? && hint[:text].size <= 143 })
      assert_equal(doc_hints.size, packet.dig(:packet, :layered_selection, :doc_hints_count))
    end
  end

  def test_docs_first_prioritizes_global_signals_by_document_terms
    Dir.mktmpdir("redwright-doc-priority-global-signals-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "README.md"), "# Parser focus\nprioritize parse_token behavior for context\n")
      File.write(File.join(dir, "lib", "a.rb"), "class Current\n  def current_run(input)\n  end\nend\n")
      File.write(File.join(dir, "lib", "b.rb"), "class Relevant\n  def parse_token(payload)\n  end\nend\n")
      File.write(File.join(dir, "lib", "c.rb"), "class Noise\n  def execute_misc(data)\n  end\nend\n")

      packet = Redwright::IterationContextPacketBuilder.new.build(
        project_path: dir,
        task_goal: "stabilize runtime flow",
        previous_message: "none",
        current_errors: [],
        parser_mode: "preferred_tree_sitter",
        lsp_mode: "fallback_disabled",
        top_k_files: 5
      )

      global_symbols = packet.dig(:packet, :ir_v1, "AVAILABLE_SYMBOLS").select { |s| s[:layer] == "GLOBAL_SIGNALS" }
      assert(global_symbols.any? { |symbol| symbol[:name].to_s.include?("parse_token") })
    end
  end
end
