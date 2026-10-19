require "test_helper"

class DumpTest < ActiveSupport::TestCase
  test "stores content and metadata in Markdown with a rebuildable index" do
    project = create_project
    feature = create_use_case(project: project)
    dump = project.dumps.create!(use_case: feature, body: "# Notes\n\nKeep this decision.")
    path = dump.relative_path
    assert_equal feature.name, dump.title
    assert_equal "draft", dump.status
    assert_equal "Keep this decision.", dump.body.lines.last.strip
    assert_not_includes Dump.column_names, "raw_body"
    assert_not_includes Dump.column_names, "body"
    assert_not ActiveRecord::Base.connection.table_exists?(:dump_entries)
    Dump.delete_all
    Dump.reconcile!(project)
    restored = project.dumps.find_by!(relative_path: path)
    assert_equal feature.id, restored.use_case_id
    assert_equal dump.body, restored.body
  end

  test "external edits refresh title status body and tags" do
    project = create_project
    dump = project.dumps.create!(body: "Old")
    dump.tag_with!("Old")
    feature = create_use_case(project: project, name: "New feature")
    entry = dump.source
    Dumps::FileStore.new(project).write(path: dump.relative_path,
      metadata: entry[:metadata].merge("title" => "Changed", "status" => "ready", "case_slug" => feature.slug, "tags" => ["Old", "Files"]),
      body: "New", revision: entry[:source_hash])
    Dump.reconcile!(project)
    assert_equal "Changed", dump.reload.title
    assert_equal "ready", dump.status
    assert_equal "New", dump.body
    assert_equal %w[files old], dump.tags.map(&:name).sort
    assert_equal [feature.id], dump.taggings.distinct.pluck(:use_case_id)
  end

  test "stale updates cannot replace an externally edited document" do
    project = create_project
    dump = project.dumps.create!(body: "Original")
    revision = dump.source_hash
    dump.update!(body: "External")
    error = assert_raises(Specifications::Error) do
      Dumps::Documents.new(project).update(dump, body: "Stale", revision: revision)
    end
    assert_equal :conflict, error.code
    assert_equal "External", dump.source[:body]
  end

  test "reopening a case reuses its single editable document" do
    project = create_project
    service = Dumps::Documents.new(project)
    dump = service.open(use_case_name: "Billing")
    service.update(dump, body: "Complete notes", revision: dump.source_hash, status: "ready")
    same = service.open(use_case_name: "Billing")
    assert_equal dump.id, same.id
    assert_equal "ready", same.status
    service.update(same, body: "Revised notes", revision: same.source_hash)
    assert_equal 1, project.dumps.count
    assert_equal "Revised notes", same.body
  end

  test "rejects duplicate case documents before changing the index" do
    project = create_project
    feature = create_use_case(project: project)
    dump = project.dumps.create!(use_case: feature)
    entry = dump.source
    Dumps::FileStore.new(project).write(path: "ops/default/dump/other/artifact.md",
      metadata: entry[:metadata].merge("slug" => "other"), body: "Duplicate")
    assert_raises(Specifications::Error) { Dump.reconcile!(project) }
    assert_equal [dump.id], project.dumps.pluck(:id)
  end

  test "missing files remove only their index and tags" do
    project = create_project
    dump = project.dumps.create!
    dump.tag_with!("Context")
    File.delete(File.join(project.root_path, dump.relative_path))
    Dump.reconcile!(project)
    assert_empty project.dumps
    assert_empty Tagging.where(taggable_type: "Dump", taggable_id: dump.id)
  end

  test "rejects foreign cases and invalid statuses without writing files" do
    project = create_project
    other_case = create_use_case
    invalid = project.dumps.new(use_case: other_case, status: "completed")
    assert_not invalid.valid?
    assert_includes invalid.errors[:use_case], "must belong to the same project"
    assert_includes invalid.errors[:status], "is not included in the list"
    assert_empty Dir.glob("#{project.root_path}/ops/**/*.md")
  end
end
