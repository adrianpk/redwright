require "test_helper"

module DumpLoops
  class CommandQueryHandlersTest < ActiveSupport::TestCase
    test "opens appends completes lists and shows dumps through dispatcher" do
      project = create_project(key: "dump-command-query-#{SecureRandom.hex(4)}")
      dispatcher = CommandQuery::ApplicationDispatcher.build

      opened = dispatcher.call(command("OpenDump", {
        project_id: project.id,
        use_case_name: "Billing Flow"
      }, request_id: "req-dump-open"))

      assert opened.ok?, opened.errors.inspect
      dump = Dump.find(opened.data.fetch("dump").fetch("id"))
      assert_equal "capturing", opened.data.fetch("status")
      assert_equal "Billing Flow", dump.use_case.name

      appended = dispatcher.call(command("AppendDump", {
        project_id: project.id,
        dump_id: dump.id,
        raw_input: "Billing reminders should avoid noisy prompts."
      }, request_id: "req-dump-append"))

      assert appended.ok?, appended.errors.inspect
      assert_equal "capturing", appended.data.fetch("status")
      assert_equal 1, appended.data.fetch("dump").fetch("entry_count")

      completed = dispatcher.call(command("DoneDump", {
        project_id: project.id,
        dump_id: dump.id
      }, request_id: "req-dump-done"))

      assert completed.ok?, completed.errors.inspect
      assert_equal "done", completed.data.fetch("status")
      assert_equal "closed", dump.reload.capture_status
      assert dump.curated_body.present?

      listed = dispatcher.call(query("ListDumps", {
        project_id: project.id
      }, request_id: "req-dump-list"))

      assert listed.ok?, listed.errors.inspect
      assert_equal [dump.id], listed.data.fetch("dumps").map { |item| item.fetch("id") }

      shown = dispatcher.call(query("ShowDump", {
        project_id: project.id,
        identifier: dump.slug
      }, request_id: "req-dump-show"))

      assert shown.ok?, shown.errors.inspect
      assert_equal dump.id, shown.data.fetch("dump").fetch("id")
      assert_includes shown.data.fetch("dump").fetch("raw_body"), "Billing reminders"
    end

    test "cancels active dump without deleting entries" do
      project = create_project(key: "dump-command-query-cancel-#{SecureRandom.hex(4)}")
      dispatcher = CommandQuery::ApplicationDispatcher.build
      dump = project.dumps.create!(title: "Cancel Me")
      dump.entries.create!(raw_input: "Keep this.", polished_input: "Keep this.")

      cancelled = dispatcher.call(command("CancelDump", {
        project_id: project.id,
        dump_id: dump.id
      }, request_id: "req-dump-cancel"))

      assert cancelled.ok?, cancelled.errors.inspect
      assert_equal "cancelled", cancelled.data.fetch("status")
      assert_equal "cancelled", dump.reload.status
      assert_equal 1, dump.entries.count
    end

    private

    def command(name, payload, request_id:)
      envelope("command", name, payload, request_id: request_id)
    end

    def query(name, payload, request_id:)
      envelope("query", name, payload, request_id: request_id)
    end

    def envelope(kind, name, payload, request_id:)
      {
        "kind" => kind,
        "name" => name,
        "payload" => payload,
        "execution_context" => {
          "actor_identifier" => "test",
          "source_channel" => "test"
        },
        "request_id" => request_id
      }
    end
  end
end
