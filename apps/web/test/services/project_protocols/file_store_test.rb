require "test_helper"

module ProjectProtocols
  class FileStoreTest < ActiveSupport::TestCase
    setup do
      @project = create_project(key: "file-protocols")
      @store = write_protocol_files(project: @project, documents: [{path: "AGENTS.md", body: "# Root"}])
    end

    # Discovery follows files, including arbitrary nested documents and deletions.
    test "discovers the current Markdown set" do
      path = @store.root.join(".agents", "custom", "EXTRA.md")
      FileUtils.mkdir_p(path.dirname)
      path.write("# Extra")
      @store.root.join(".agents", "ignored.txt").write("ignored")
      assert_equal ["AGENTS.md", ".agents/custom/EXTRA.md"], @store.documents.map(&:path)
      path.delete
      assert_equal ["AGENTS.md"], @store.documents.map(&:path)
    end

    # Both the web and agent state must observe edits made outside RW.
    test "reads external edits without reimport" do
      @store.root.join("AGENTS.md").write("# External edit")
      assert_equal "# External edit", @project.protocol_state.fetch("documents").first.fetch("body")
      refute @project.protocol_state.key?("id")
    end

    # Saving one file must preserve all other files and permit an empty body.
    test "writes only the selected file" do
      other = @store.create(".agents/OTHER.md", "unchanged")
      document = @store.find_path("AGENTS.md")
      assert document.update(body: "", revision: document.revision)
      assert_equal "", @store.root.join("AGENTS.md").read
      assert_equal "unchanged", other.reload.body
    end

    # A stale browser must not overwrite newer edits from another tool.
    test "rejects stale revisions" do
      document = @store.find_path("AGENTS.md")
      @store.root.join("AGENTS.md").write("newer")
      refute document.update(body: "stale", revision: document.revision)
      assert_equal "newer", @store.root.join("AGENTS.md").read
    end

    # URL identifiers cannot grant access outside the protocol file boundary.
    test "rejects paths outside the protocol set" do
      {"traversal" => ".agents/../../outside.md", "absolute" => "/tmp/outside.md", "other root file" => "README.md", "non Markdown" => ".agents/config.yml"}.each do |name, path|
        assert_raises(ActiveRecord::RecordNotFound, name) { @store.find(Base64.urlsafe_encode64(path, padding: false)) }
        assert_raises(ArgumentError, name) { @store.create(path, "outside") }
      end
    end

    # Symlinks must not expose or modify files outside the selected workspace.
    test "rejects escaping symlinks" do
      Dir.mktmpdir("outside-protocols-") do |outside|
        target = Pathname.new(outside).join("PRIVATE.md")
        target.write("private")
        FileUtils.mkdir_p(@store.root.join(".agents"))
        File.symlink(target, @store.root.join(".agents", "LINK.md"))
        File.symlink(outside, @store.root.join(".agents", "outside"))
        assert_equal ["AGENTS.md"], @store.documents.map(&:path)
        assert_raises(ArgumentError) { @store.create(".agents/outside/nested/NEW.md", "bad") }
        refute Pathname.new(outside).join("nested").exist?
      end
    end

    # Viewing an unavailable workspace must not create it or seed documents.
    test "reads missing workspaces without side effects" do
      missing = @store.root.join("missing")
      assert_equal [], FileStore.new(root: missing).documents
      refute missing.exist?
    end
  end
end
