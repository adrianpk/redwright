require "test_helper"
require "fileutils"
require "tmpdir"
require "yaml"

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

  test "rails-backed protocol updates overwrite local materialized files" do
    with_local_projects_root do |projects_root|
      project = create_project(key: "project-protocol-sync")
      project.update!(repo_url: "local://project-protocol-sync")
      workspace_path = File.join(projects_root, "project-protocol-sync")
      FileUtils.mkdir_p(File.join(workspace_path, ".redwright"))
      File.write(File.join(workspace_path, ".redwright", "manifest.yml"), YAML.dump({"schema_version" => 1}))

      protocol = create_project_protocol(
        project: project,
        documents: [{key: "agents_root", path: "AGENTS.md", title: "AGENTS", body: "# Initial"}]
      )
      File.write(File.join(workspace_path, "AGENTS.md"), "# Manual edit\n")

      protocol.documents.first.update!(body: "# From Rails")

      assert_equal "# From Rails\n", File.read(File.join(workspace_path, "AGENTS.md"))
      manifest = YAML.safe_load(File.read(File.join(workspace_path, ".redwright", "manifest.yml")))
      assert_equal ["AGENTS.md"], manifest.dig("protocols", "files").map { |entry| entry.fetch("path") }
    end
  end

  private

  def with_local_projects_root
    previous = ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"]
    Dir.mktmpdir("redwright-local-projects-") do |dir|
      ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"] = dir
      yield dir
    ensure
      if previous.nil?
        ENV.delete("REDWRIGHT_LOCAL_PROJECTS_ROOT")
      else
        ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"] = previous
      end
    end
  end
end
