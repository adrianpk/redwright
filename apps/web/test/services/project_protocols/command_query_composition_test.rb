require "test_helper"

module ProjectProtocols
  class CommandQueryCompositionTest < ActiveSupport::TestCase
    test "command composes protocols from seeded templates" do
      project = create_project(name: "Seeded Go", key: "protocol-compose-go")
      write_setup_attribute(project, "language_runtime", "Go 1.22", 5)
      write_setup_attribute(project, "framework", "none", 4)

      result = dispatcher.call(
        "kind" => "command",
        "name" => "ComposeProjectProtocols",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-compose-project-protocols"
      )

      assert result.ok?
      assert_equal "Project Protocols composed from seeded templates.", result.data.fetch("summary")
      assert_equal "project_protocols_composed", result.effects.first.fetch("type")
      assert_includes result.data.fetch("composition").fetch("stack_keys"), "go"
      assert_equal "AGENTS.md", result.data.fetch("generated_protocols").fetch("documents").first.fetch("path")
    end

    test "command reports fallback composition when coverage is missing" do
      project = create_project(name: "Fallback Stack", key: "protocol-compose-fallback")
      write_setup_attribute(project, "language_runtime", "Cobol 1.0", 5)

      result = dispatcher.call(
        "kind" => "command",
        "name" => "ComposeProjectProtocols",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-compose-project-protocols-fallback"
      )

      assert result.ok?
      assert_equal "Project Protocols composed with generated fallback for missing stack coverage.", result.data.fetch("summary")
      assert_equal true, result.data.fetch("composition").fetch("fallback_used")
      assert_includes result.data.fetch("composition").fetch("missing_stack_tokens"), "Cobol 1.0"
    end

    private

    def dispatcher
      CommandQuery::ApplicationDispatcher.build
    end

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
