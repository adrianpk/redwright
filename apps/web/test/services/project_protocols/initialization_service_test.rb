require "test_helper"

module ProjectProtocols
  class InitializationServiceTest < ActiveSupport::TestCase
    test "persists seeded project protocols for supported stack context" do
      project = create_project(name: "Protocol Init", key: "protocol-init-go")
      write_setup_attribute(project, "language_runtime", "Go 1.22", 5)
      write_setup_attribute(project, "framework", "none", 4)

      result = InitializationService.new(project: project).call

      assert result.persisted?
      assert_includes result.stack_keys, "go"
      state = project.reload.protocol_state
      assert_equal "draft", state.fetch("status")
      assert_equal "AGENTS.md", state.fetch("documents").first.fetch("path")
      assert_match(/Repository Architecture/, state.fetch("documents").find { |doc| doc.fetch("key") == "architecture" }.fetch("body"))
    end

    test "persists fallback project protocols when stack coverage is missing" do
      project = create_project(name: "Protocol Init Fallback", key: "protocol-init-fallback")
      write_setup_attribute(project, "language_runtime", "Cobol 1.0", 5)

      result = InitializationService.new(project: project).call

      assert result.persisted?
      assert_equal true, result.fallback_used
      assert_includes result.missing_stack_tokens, "Cobol 1.0"
      architecture = project.reload.protocol_state.fetch("documents").find { |doc| doc.fetch("key") == "architecture" }
      assert_equal "generated_during_initialization", architecture.fetch("provenance").fetch("source")
    end

    private

    def write_setup_attribute(project, slot, value, weight)
      ProjectAttribute.create!(
        project: project,
        key: "setup_context.#{slot}",
        value: value,
        weight: weight,
        source: "project_setup"
      )
    end
  end
end
