require "test_helper"

class ProjectProtocolTest < ActiveSupport::TestCase
  test "belongs to one project protocol state" do
    project = create_project(key: "project-protocol-owner")
    protocol = create_project_protocol(project: project, documents: [{key: "agents_root", path: "AGENTS.md", title: "AGENTS", body: "Root"}])

    assert_equal protocol, project.reload.protocol
    assert_equal project.id, protocol.to_state.fetch("project_id")
    assert_equal "AGENTS.md", protocol.to_state.fetch("documents").first.fetch("path")
  end

  test "defaults to explicit draft state" do
    protocol = ProjectProtocol.create!(project: create_project(key: "project-protocol-defaults"))

    assert_equal "draft", protocol.status
  end

  test "validates status contract" do
    protocol = ProjectProtocol.new(project: create_project(key: "project-protocol-status"), status: "unknown")

    assert_not protocol.valid?
    assert_includes protocol.errors[:status], "is not included in the list"
  end

  test "persists ordered documents with layer and provenance" do
    protocol = create_project_protocol(
      project: create_project(key: "project-protocol-docs"),
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
          key: "architecture",
          path: ".agents/ARCHITECTURE.md",
          title: "Architecture",
          layer: "stack",
          position: 1,
          body: "Rails architecture guidance.",
          provenance: {"source" => "stack_template", "stack" => "rails"}
        }
      ]
    )

    state = protocol.reload.to_state
    assert_equal ["agents_root", "architecture"], state.fetch("documents").map { |doc| doc.fetch("key") }
    assert_equal "behavioral", state.fetch("documents").first.fetch("layer")
    assert_equal "stack", state.fetch("documents").second.fetch("layer")
    assert_equal "rails", state.fetch("documents").second.fetch("provenance").fetch("stack")
  end

  test "project exposes missing protocol state without a record" do
    project = create_project(key: "project-protocol-missing")

    state = project.protocol_state

    assert_nil state.fetch("id")
    assert_equal project.id, state.fetch("project_id")
    assert_equal "missing", state.fetch("status")
    assert_equal [], state.fetch("documents")
  end
end
