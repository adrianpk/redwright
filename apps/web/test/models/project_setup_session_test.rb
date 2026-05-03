require "test_helper"

class ProjectSetupSessionTest < ActiveSupport::TestCase
  test "is valid with required actor and request metadata" do
    session = ProjectSetupSession.new(
      actor_identifier: "human-1",
      request_id: "req-setup-1"
    )

    assert session.valid?, session.errors.full_messages.inspect
    assert_equal "web", session.source_channel
    assert_equal "open", session.status
    assert_equal "collecting_context", session.current_state
    assert_equal 0, session.turn_counter
  end

  test "can be associated with a project when project already exists" do
    project = create_project(key: "setup-associated-project")

    session = ProjectSetupSession.create!(
      project: project,
      actor_identifier: "agent-coder",
      request_id: "req-associated"
    )

    assert_equal [session.id], project.project_setup_sessions.pluck(:id)
  end

  test "requires actor and request metadata" do
    session = ProjectSetupSession.new

    assert_not session.valid?
    assert_includes session.errors[:actor_identifier], "can't be blank"
    assert_includes session.errors[:request_id], "can't be blank"
  end

  test "rejects unsupported status and current state" do
    session = ProjectSetupSession.new(
      actor_identifier: "human-1",
      request_id: "req-invalid",
      status: "whatever",
      current_state: "unknown"
    )

    assert_not session.valid?
    assert_includes session.errors[:status], "is not included in the list"
    assert_includes session.errors[:current_state], "is not included in the list"
  end

  test "terminal setup states require terminal reason" do
    session = ProjectSetupSession.new(
      actor_identifier: "human-1",
      request_id: "req-terminal",
      current_state: "completed",
      status: "completed"
    )

    assert_not session.valid?
    assert_includes session.errors[:terminal_reason], "is required for terminal setup states"
  end

  test "json accessors normalize hash payloads" do
    session = ProjectSetupSession.new(
      actor_identifier: "human-1",
      request_id: "req-json"
    )
    session.resolved_repository = {canonical: "https://codeberg.org/acme/rw.git", source: :url}
    session.metadata = {chat_id: 42}

    assert_equal(
      {"canonical" => "https://codeberg.org/acme/rw.git", "source" => "url"},
      session.resolved_repository
    )
    assert_equal({"chat_id" => 42}, session.metadata)
  end

  test "setup context defaults to canonical slot collection" do
    session = ProjectSetupSession.new(
      actor_identifier: "human-1",
      request_id: "req-setup-context"
    )

    assert_equal 1, session.setup_context.fetch("version")
    assert_equal "canonical_slot_collection", session.setup_context.fetch("phase")
    assert_equal({}, session.setup_slots)
  end

  test "writes canonical setup slots into metadata" do
    session = ProjectSetupSession.create!(
      actor_identifier: "human-1",
      request_id: "req-setup-slot"
    )

    session.write_setup_slot!(
      key: :project_name,
      value: "notes-cli",
      source: "payload",
      updated_at: Time.utc(2026, 5, 3, 12, 0, 0)
    )

    slot = session.reload.setup_slot(:project_name)
    assert_equal "project_name", slot.fetch("key")
    assert_equal "notes-cli", slot.fetch("value")
    assert_equal "payload", slot.fetch("source")
    assert_equal "blocking", slot.fetch("requiredness")
    assert_equal "filled", slot.fetch("status")
    assert_equal 10, slot.fetch("weight")
    assert_equal "2026-05-03T12:00:00Z", slot.fetch("updated_at")
  end

  test "rejects unknown setup slots" do
    session = ProjectSetupSession.new(
      actor_identifier: "human-1",
      request_id: "req-unknown-slot"
    )

    error = assert_raises(ArgumentError) do
      session.assign_setup_slot(key: :unknown, value: "x", source: "payload")
    end
    assert_equal "unknown setup slot: unknown", error.message
  end

  test "next turn index follows existing persisted turns" do
    session = ProjectSetupSession.create!(actor_identifier: "human-1", request_id: "req-turn-index")
    session.project_setup_turns.create!(
      turn_index: 1,
      source_channel: "web",
      question: "Repository?",
      answer: "acme/repo"
    )

    assert_equal 2, session.next_turn_index
  end
end
