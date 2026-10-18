require "test_helper"

module ProjectProtocols
  class ComposerTest < ActiveSupport::TestCase
    # Base instructions remain separate from stack-specific concern files.
    test "composes current files with matching stack overlays" do
      project = create_project(key: "compose-rails")
      ProjectAttribute.create!(project: project, key: "setup_context.framework", value: "Rails", weight: 4, source: "project_setup")
      result = Composer.new(project: project).call
      assert_includes result.stack_keys, "ruby"
      assert_includes result.stack_keys, "rails"
      paths = result.documents.map { |document| document.fetch("path") }
      assert_equal "AGENTS.md", paths.first
      assert_includes paths, ".agents/COMMUNICATION.md"
      assert_includes paths, ".agents/stacks/rails/ARCHITECTURE.md"
      assert_includes paths, ".agents/stacks/ruby/CONVENTIONS.md"
      refute_includes paths, ".agents/stacks/go/CONVENTIONS.md"
    end

    test "reports unsupported stack tokens" do
      project = create_project(key: "compose-unknown")
      project.update!(stack_slug: "unknown-language")
      result = Composer.new(project: project).call
      assert result.fallback_used
      assert_includes result.missing_stack_tokens, "unknown-language"
      assert_includes result.documents.map { |document| document.fetch("path") }, "AGENTS.md"
    end
  end
end
