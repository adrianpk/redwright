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
        top_k_files: 2
      )

      assert_equal(2, packet[:summary][:top_files_count])
      assert_equal(2, packet[:summary][:top_files].size)
      assert_equal("v2", packet.dig(:packet, :version))
      assert_equal("unknown", packet.dig(:packet, :stack_hints, :ecosystem))
      assert_includes(packet[:prompt_text], "Semantic Context Packet v2")
      assert_includes(packet[:prompt_text], "task_goal: fix failing test")
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
end
