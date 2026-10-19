require "test_helper"

class DumpLegacyExporterTest < ActiveSupport::TestCase
  test "preserves captured notes useful synthesis scope and status in one document" do
    project = create_project
    feature = create_use_case(project: project)
    rows = [{"id" => 42, "title" => "Billing", "slug" => "billing", "use_case_id" => feature.id,
      "status" => "completed", "created_at" => Time.current.iso8601,
      "raw_body" => "Polished note", "curated_body" => "# Synthesis\n\nUseful decision.", "summary" => "Useful decision."}]
    notes = [{"dump_id" => 42, "position" => 1, "raw_input" => "Original note", "polished_input" => "Polished note"}]
    entries = Dumps::LegacyExporter.new(project: project, dumps: rows, entries: notes, tags: {42 => ["billing"]}).export!
    entry = entries.fetch(0)
    assert_includes entry[:body], "Original note"
    assert_includes entry[:body], "Polished note"
    assert_includes entry[:body], "Useful decision."
    assert_equal 1, entry[:body].scan("Polished note").size
    assert_equal "ready", entry[:status]
    Dump.reconcile!(project)
    assert_equal feature.id, project.dumps.sole.use_case_id
    assert_equal ["billing"], project.dumps.sole.tags.map(&:name)
    path = Pathname.new(project.root_path).join(entry[:path])
    path.write(path.read + "\nUser edit")
    assert_raises(Specifications::Error) { Dumps::LegacyExporter.new(project: project, dumps: rows, entries: notes).export! }
    assert_includes path.read, "User edit"
  end

  test "does not repeat a fallback synthesis that only echoes the captured notes" do
    project = create_project
    row = {"id" => 4, "title" => "Notes", "slug" => "notes", "status" => "completed", "created_at" => Time.current.iso8601,
      "raw_body" => "More details\n\nRemember this", "curated_body" => "# Notes\n\n## Summary\nMore details\n\nRemember this"}
    entry = Dumps::LegacyExporter.new(project: project, dumps: [row]).export!.sole
    assert_equal "More details\n\nRemember this", entry[:body]
  end

  test "does not preserve the generated no-content placeholder as a synthesis" do
    project = create_project
    row = {"id" => 3, "title" => "Notes", "slug" => "notes", "status" => "active", "created_at" => Time.current.iso8601,
      "raw_body" => "More details\n\nRemember this", "curated_body" => "# Old title\n\nNo dump content was available for curation."}
    entry = Dumps::LegacyExporter.new(project: project, dumps: [row]).export!.sole
    assert_equal "More details\n\nRemember this", entry[:body]
    assert_equal "draft", entry[:status]
  end
end
