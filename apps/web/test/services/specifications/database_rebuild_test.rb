require "test_helper"
require_relative "../../support/harness_database_fixture"

class SpecificationsDatabaseRebuildTest < ActiveSupport::TestCase
  include HarnessDatabaseFixture

  test "legacy preparation leaves the source schema unchanged" do
    # Adoption creates the new tables only in the owned prepared database.
    project = create_project(name: "Legacy factory fixture")
    document = create_document(project: project, status: "approved")
    original = document.source
    ActiveRecord::Base.connection.drop_table(:harness_operations)
    ActiveRecord::Base.connection.drop_table(:project_harness_settings)
    output = File.join(@harness_fixture_root, "legacy-prepared.sqlite3")
    Specifications::DatabaseRebuild.prepare!(output_path: output)
    assert_not ActiveRecord::Base.connection.table_exists?(:harness_operations)
    assert_not ActiveRecord::Base.connection.table_exists?(:project_harness_settings)
    assert_equal original, document.source
    target = SQLite3::Database.new(output)
    assert_equal 0, target.get_first_value("SELECT count(*) FROM project_harness_settings")
    assert_equal 0, target.get_first_value("SELECT count(*) FROM harness_operations")
    assert_equal "Legacy factory fixture", target.get_first_value("SELECT name FROM projects WHERE id = ?", [project.id])
    assert_equal document.relative_path, target.get_first_value("SELECT relative_path FROM documents WHERE id = ?", [document.id])
  ensure
    target&.close
  end

  test "preparation preserves domain data and harness provenance" do
    # Both databases and every associated workspace file belong to this fixture.
    project = create_project(name: "Factory fixture")
    user = User.create!(email_address: "operator@example.test", password: "password-123")
    spec = create_document(project: project, status: "approved")
    dump = project.dumps.create!(body: "Original discovery", status: "ready")
    board = create_board(project: project)
    column = board.columns.create!(key: "backlog", title: "Ready", position: 0)
    ticket = board.tickets.create!(column: column, title: "Keep fixture work", use_case: spec.use_case)
    setting = ProjectHarnessSetting.create!(project: project, authoring_profile: "local", changed_by: user)
    store = Harnesses::BindingStore.new(directory: File.join(@harness_fixture_root, "bindings"))
    # The retained ticket role keeps the default direct API without resolving authoring profiles.
    operation = Harnesses::Selection.new(project: project, store: store).admit!(operation_key: "retained",
      purpose: "ticket_proposal", role: "ticket_proposal", schema: {}, policy_revision: "v1")
    rows = {"project_harness_settings" => setting.attributes, "harness_operations" => operation.attributes}
    files = [spec, dump, ticket].to_h { |record| [record.relative_path, File.binread(File.join(project.root_path, record.relative_path))] }
    output = File.join(@harness_fixture_root, "prepared.sqlite3")
    result = Specifications::DatabaseRebuild.prepare!(output_path: output)
    assert_equal @harness_fixture_database, ActiveRecord::Base.connection_db_config.database
    assert_equal setting.attributes, setting.reload.attributes
    assert_equal operation.attributes, operation.reload.attributes
    assert File.file?(result.fetch(:source_snapshot))
    target = SQLite3::Database.new(output)
    target.results_as_hash = true
    rows.each do |table, values|
      row = target.get_first_row("SELECT * FROM #{table} WHERE id = ?", [values.fetch("id")])
      values.except("created_at", "updated_at").each do |key, value|
        value.nil? ? assert_nil(row[key], "#{table}.#{key}") : assert_equal(value, row[key], "#{table}.#{key}")
      end
    end
    assert_equal "Factory fixture", target.get_first_value("SELECT name FROM projects WHERE id = ?", [project.id])
    assert_equal ticket.relative_path, target.get_first_value("SELECT relative_path FROM tickets WHERE id = ?", [ticket.id])
    assert_empty target.execute("PRAGMA foreign_key_check")
    files.each { |path, bytes| assert_equal bytes, File.binread(File.join(project.root_path, path)) }
  ensure
    target&.close
  end
end
