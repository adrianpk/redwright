require "test_helper"

module RuntimeBridge
  class ProjectContextBuilderTest < ActiveSupport::TestCase
    test "builds runtime context from project setup attributes with safe defaults" do
      project = create_project(name: "Runtime Context", key: "runtime-context-#{SecureRandom.hex(4)}")
      project.project_attributes.create!(key: "setup_context.language_runtime", value: "Node.js 22", weight: 5, source: "project_setup")
      project.project_attributes.create!(key: "setup_context.framework", value: "Fastify", weight: 4, source: "project_setup")
      project.project_attributes.create!(key: "setup_context.libraries", value: "SQLite", weight: 3, source: "project_setup")

      context = ProjectContextBuilder.new(project: project).build

      assert_equal project.name, context.dig("project", "name")
      assert_equal "Node.js 22", context.dig("slots", "language_runtime", "value")
      assert_equal "Fastify", context.dig("slots", "framework", "value")
      assert_equal "SQLite", context.dig("runtime", "libraries")
      assert_equal "ephemeral_docker", context.dig("runtime", "container_profile")
      assert_equal "manual", context.dig("runtime", "agent_workflow_mode")
      assert_equal "runtime_default", context.dig("slots", "runtime_container_profile", "source")
      assert_equal "missing", context.dig("operational_setup", "status")
      assert_equal "rw/agent/Dockerfile", context.dig("operational_setup", "dockerfile_relative_path")
    end
  end
end
