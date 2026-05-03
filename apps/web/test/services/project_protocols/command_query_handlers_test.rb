require "test_helper"

module ProjectProtocols
  class CommandQueryHandlersTest < ActiveSupport::TestCase
    test "queries missing protocols state for project" do
      project = create_project(key: "project-protocols-query-missing")

      result = dispatcher.call(
        "kind" => "query",
        "name" => "GetProjectProtocols",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-project-protocols-missing"
      )

      assert result.ok?
      state = result.data.fetch("protocols")
      assert_equal "Project Protocols retrieved.", result.data.fetch("summary")
      assert_equal project.id, result.data.fetch("project_id")
      assert_equal "missing", state.fetch("status")
      assert_equal [], state.fetch("documents")
    end

    test "queries persisted protocols state" do
      project = create_project(key: "project-protocols-query-existing")
      create_project_protocol(
        project: project,
        documents: [
          {
            key: "agents_root",
            path: "AGENTS.md",
            title: "AGENTS",
            layer: "behavioral",
            position: 0,
            body: "Read AGENTS first.",
            provenance: {"source" => "common_template"}
          },
          {
            key: "conventions",
            path: ".agents/CONVENTIONS.md",
            title: "Conventions",
            layer: "stack",
            position: 1,
            body: "Rails conventions.",
            provenance: {"source" => "stack_template", "stack" => "rails"}
          }
        ]
      )

      result = dispatcher.call(
        "kind" => "query",
        "name" => "GetProjectProtocols",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-project-protocols-existing"
      )

      assert result.ok?
      state = result.data.fetch("protocols")
      assert_equal "draft", state.fetch("status")
      assert_equal "AGENTS.md", state.fetch("documents").first.fetch("path")
      assert_equal "stack", state.fetch("documents").second.fetch("layer")
      assert_equal "rails", state.fetch("documents").second.fetch("provenance").fetch("stack")
    end

    test "project query includes protocols state" do
      project = create_project(key: "project-protocols-project-query")
      create_project_protocol(
        project: project,
        documents: [{key: "agents_root", path: "AGENTS.md", title: "AGENTS", layer: "behavioral", body: "Root"}]
      )

      result = dispatcher.call(
        "kind" => "query",
        "name" => "GetProject",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-project-protocols-project"
      )

      assert result.ok?
      protocols_state = result.data.fetch("project").fetch("protocols")
      assert_equal "draft", protocols_state.fetch("status")
      assert_equal "AGENTS.md", protocols_state.fetch("documents").first.fetch("path")
    end

    private

    def dispatcher
      CommandQuery::ApplicationDispatcher.build
    end
  end
end
