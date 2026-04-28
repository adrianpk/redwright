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
      assert_includes(packet[:prompt_text], "Semantic Context Packet v2")
      assert_includes(packet[:prompt_text], "task_goal: fix failing test")
      assert_includes(packet[:prompt_text], "content: |")
      assert_operator(packet[:summary][:packet_bytes], :>, 0)
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
end
