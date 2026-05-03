require "test_helper"
require "fileutils"
require "tmpdir"
require "yaml"

module ProjectProtocols
  class FilesystemMaterializerTest < ActiveSupport::TestCase
    test "materializes project protocol files into the local workspace" do
      with_local_projects_root do |projects_root|
        project = create_project(name: "Protocol Files", key: "protocol-files")
        project.update!(repo_url: "local://protocol-files")
        create_project_protocol(
          project: project,
          documents: [
            {key: "agents_root", path: "AGENTS.md", title: "AGENTS", body: "# Root"},
            {key: "architecture", path: ".agents/ARCHITECTURE.md", title: "Architecture", body: "# Architecture"},
            {key: "playbooks_index", path: ".agents/PLAYBOOKS.md", title: "Playbooks", body: "# Playbooks"},
            {key: "playbook_slice_delivery", path: ".agents/playbooks/slice-delivery.md", title: "Slice Delivery", body: "# Slice Delivery"}
          ]
        )
        workspace_path = File.join(projects_root, "protocol-files")
        manifest_dir = File.join(workspace_path, ".redwright")
        FileUtils.mkdir_p(manifest_dir)
        File.write(File.join(manifest_dir, "manifest.yml"), YAML.dump({"schema_version" => 1}))

        result = FilesystemMaterializer.new(project: project).call(update_manifest: true)

        assert_equal "materialized", result.fetch("status")
        assert_equal workspace_path, result.fetch("workspace_path")
        assert File.file?(File.join(workspace_path, "AGENTS.md"))
        assert File.file?(File.join(workspace_path, ".agents", "ARCHITECTURE.md"))
        assert File.file?(File.join(workspace_path, ".agents", "PLAYBOOKS.md"))
        assert File.file?(File.join(workspace_path, ".agents", "playbooks", "slice-delivery.md"))
        assert_equal "# Root\n", File.read(File.join(workspace_path, "AGENTS.md"))
        manifest = YAML.safe_load(File.read(File.join(manifest_dir, "manifest.yml")))
        assert_equal "materialized", manifest.dig("protocols", "status")
        assert_equal "AGENTS.md", manifest.dig("protocols", "root_entrypoint")
        assert_equal(
          ["AGENTS.md", ".agents/ARCHITECTURE.md", ".agents/PLAYBOOKS.md", ".agents/playbooks/slice-delivery.md"],
          manifest.dig("protocols", "files").map { |entry| entry.fetch("path") }
        )
      end
    end

    test "removes stale protocol files tracked in the manifest" do
      with_local_projects_root do |projects_root|
        project = create_project(name: "Protocol Refresh", key: "protocol-refresh")
        project.update!(repo_url: "local://protocol-refresh")
        create_project_protocol(
          project: project,
          documents: [
            {key: "agents_root", path: "AGENTS.md", title: "AGENTS", body: "# Root"},
            {key: "architecture", path: ".agents/ARCHITECTURE.md", title: "Architecture", body: "# Architecture"}
          ]
        )
        workspace_path = File.join(projects_root, "protocol-refresh")
        manifest_dir = File.join(workspace_path, ".redwright")
        stale_path = File.join(workspace_path, ".agents", "playbooks", "legacy.md")
        FileUtils.mkdir_p(File.dirname(stale_path))
        FileUtils.mkdir_p(manifest_dir)
        File.write(stale_path, "# Legacy\n")
        File.write(
          File.join(manifest_dir, "manifest.yml"),
          YAML.dump(
            {
              "schema_version" => 1,
              "protocols" => {
                "status" => "materialized",
                "root_entrypoint" => "AGENTS.md",
                "files" => [
                  {"path" => "AGENTS.md"},
                  {"path" => ".agents/ARCHITECTURE.md"},
                  {"path" => ".agents/playbooks/legacy.md"}
                ]
              }
            }
          )
        )

        FilesystemMaterializer.new(project: project).call(update_manifest: true)

        refute File.exist?(stale_path)
        manifest = YAML.safe_load(File.read(File.join(manifest_dir, "manifest.yml")))
        assert_equal ["AGENTS.md", ".agents/ARCHITECTURE.md"], manifest.dig("protocols", "files").map { |entry| entry.fetch("path") }
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
end
