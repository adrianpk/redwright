require "test_helper"

module ProjectProtocols
  class ComposerTest < ActiveSupport::TestCase
    test "composes baseline protocols from project stack context" do
      project = create_project(name: "Common Only", key: "protocol-common-only")

      result = Composer.new(project: project).call

      assert_includes result.stack_keys, "ruby"
      assert_equal [], result.missing_stack_tokens
      assert_not result.fallback_used
      assert_equal "AGENTS.md", result.documents.first.fetch("path")
      assert_equal "behavioral", result.documents.first.fetch("layer")
      assert_equal "common_template", result.documents.first.fetch("provenance").fetch("source")
    end

    test "composes stack overlays for rails and ruby context" do
      project = create_project(name: "Rails App", key: "protocol-rails")
      write_setup_attribute(project, "language_runtime", "Ruby 3.4", 5)
      write_setup_attribute(project, "framework", "Rails", 4)

      result = Composer.new(project: project).call

      assert_includes result.stack_keys, "ruby"
      assert_includes result.stack_keys, "rails"
      architecture = result.documents.find { |document| document.fetch("key") == "architecture" }
      conventions = result.documents.find { |document| document.fetch("key") == "conventions" }
      assert_equal "stack", architecture.fetch("layer")
      assert_match(/Rails Architecture/, architecture.fetch("body"))
      assert_equal "rails", architecture.fetch("provenance").fetch("stack_key")
      assert_match(/Rails Conventions/, conventions.fetch("body"))
    end

    test "uses generated fallback when stack coverage is missing" do
      project = create_project(name: "Unknown Stack", key: "protocol-zed")
      write_setup_attribute(project, "language_runtime", "UnknownLang 1.0", 5)
      write_setup_attribute(project, "framework", "none", 4)

      result = Composer.new(project: project).call

      assert result.fallback_used
      assert_includes result.missing_stack_tokens, "UnknownLang 1.0"
      architecture = result.documents.find { |document| document.fetch("key") == "architecture" }
      assert_equal "generated_during_initialization", architecture.fetch("provenance").fetch("source")
      assert_match(/Initialization Notes/, architecture.fetch("body"))
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
