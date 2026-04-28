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
      assert_includes(packet[:prompt_text], "Context packet (bounded):")
      assert_includes(packet[:prompt_text], "task_goal: fix failing test")
      assert_includes(packet[:prompt_text], "content: |")
    end
  end
end
