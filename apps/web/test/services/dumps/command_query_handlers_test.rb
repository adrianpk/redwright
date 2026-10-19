require "test_helper"

class DumpCommandQueryHandlersTest < ActiveSupport::TestCase
  test "commands replace a scoped document and detect stale revisions" do
    project = create_project
    other = create_project(key: "other")
    dispatcher = CommandQuery::ApplicationDispatcher.build
    opened = dispatcher.call({kind: "command", name: "OpenDump", payload: {"project_id" => project.id, "use_case_name" => "Billing"}, execution_context: {}, request_id: "open"}.stringify_keys)
    dump = opened.data.fetch("dump")
    payload = {"project_id" => project.id, "dump_id" => dump.fetch("id"), "body" => "Complete document", "revision" => dump.fetch("revision")}
    saved = dispatcher.call({kind: "command", name: "UpdateDump", payload: payload, execution_context: {}, request_id: "save"}.stringify_keys)
    assert saved.ok?
    assert_equal "Complete document", saved.data.fetch("dump").fetch("body")
    stale = dispatcher.call({kind: "command", name: "UpdateDump", payload: payload.merge("body" => "Stale"), execution_context: {}, request_id: "stale"}.stringify_keys)
    assert_equal "conflict", stale.errors.first.fetch(:code)
    foreign = dispatcher.call({kind: "command", name: "UpdateDump", payload: payload.merge("project_id" => other.id), execution_context: {}, request_id: "foreign"}.stringify_keys)
    assert_equal "dump_not_found", foreign.errors.first.fetch(:code)
    assert_equal "Complete document", project.dumps.sole.body
  end
end
