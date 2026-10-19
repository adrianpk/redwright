require "test_helper"

class DumpFileStoreTest < ActiveSupport::TestCase
  test "rejects paths outside the project and oversized documents" do
    project = create_project
    store = Dumps::FileStore.new(project)
    metadata = {"title" => "Notes", "artifact_type" => "dump", "status" => "draft"}
    assert_raises(Specifications::Error) { store.write(path: "../escape.md", metadata: metadata, body: "Private") }
    outside = Dir.mktmpdir("dump-outside-")
    begin
      FileUtils.mkdir_p(File.join(project.root_path, "ops/default"))
      File.symlink(outside, File.join(project.root_path, "ops/default/dump"))
      assert_raises(Specifications::Error) { store.write(path: nil, metadata: metadata, body: "Escape") }
      assert_empty Dir.children(outside)
    ensure
      FileUtils.remove_entry(outside)
    end
    assert_raises(Specifications::Error) { store.write(path: nil, metadata: metadata, body: "x" * (Specifications::FileStore::MAX_BYTES + 1)) }
  end

  test "rejects invalid file metadata without replacing the index" do
    project = create_project
    dump = project.dumps.create!(body: "Existing")
    path = Pathname.new(project.root_path).join(dump.relative_path)
    path.write("---\nstatus: closed\n---\n\nChanged")
    assert_raises(Specifications::Error) { Dump.reconcile!(project) }
    assert_equal dump.source_hash, dump.reload.source_hash
  end
end
