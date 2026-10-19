require "test_helper"
require_relative "../../support/harness_database_fixture"

class HarnessesOperationTest < ActiveSupport::TestCase
  include HarnessDatabaseFixture

  setup do
    @project = create_project
    @store = Harnesses::BindingStore.new(directory: File.join(@harness_fixture_root, "bindings"))
    @selection = Harnesses::Selection.new(project: @project, store: @store)
    @lifecycle = Harnesses::Operation.new(store: @store)
  end

  test "owned calls share capacity and reconcile uncertainty" do
    # Uncertain calls retain their slot until the same owner reconciles the outcome.
    first = @lifecycle.start!(operation: admit("one"))
    second = @lifecycle.start!(operation: admit("two", purpose: "ticket_proposal"))
    third = admit("three")
    assert_equal :capacity, assert_raises(Harnesses::Error) { @lifecycle.start!(operation: third) }.code
    @lifecycle.finish!(lease: first, outcome: "uncertain")
    assert_equal :capacity, assert_raises(Harnesses::Error) { @lifecycle.start!(operation: third) }.code
    error = assert_raises(Harnesses::Error) do
      @lifecycle.finish!(lease: first.with(owner_token: "different-owner"), outcome: "completed")
    end
    assert_equal :conflict, error.code
    completed = @lifecycle.finish!(lease: first, outcome: "completed", artifact_ref: "spec/one")
    assert_equal completed.id, @lifecycle.finish!(lease: first, outcome: "completed", artifact_ref: "spec/one").id
    assert_equal :conflict, assert_raises(Harnesses::Error) { @lifecycle.finish!(lease: first, outcome: "failed") }.code
    third_lease = @lifecycle.start!(operation: third)
    assert_equal first.binding, completed.binding
    @lifecycle.finish!(lease: second, outcome: "failed")
    @lifecycle.finish!(lease: third_lease, outcome: "cancelled")
    assert_equal 0, HarnessOperation.where(state: %w[running uncertain]).count
  end

  test "attempt limits preserve caller policy" do
    # Authoring never gains retries; ticket proposals retain exactly three attempts.
    authoring = admit("authoring")
    lease = @lifecycle.start!(operation: authoring)
    @lifecycle.finish!(lease: lease, outcome: "failed")
    assert_equal :attempt_limit, assert_raises(Harnesses::Error) { @lifecycle.start!(operation: authoring) }.code
    ticket = admit("ticket", purpose: "ticket_proposal")
    3.times do
      lease = @lifecycle.start!(operation: ticket)
      @lifecycle.finish!(lease: lease, outcome: "failed")
    end
    assert_equal :attempt_limit, assert_raises(Harnesses::Error) { @lifecycle.start!(operation: ticket) }.code
    assert_equal 3, ticket.reload.attempts.size
  end

  private

  def admit(key, purpose: "specification")
    @selection.admit!(operation_key: key, purpose: purpose, role: purpose == "ticket_proposal" ? "ticket_proposal" : "authoring", schema: {}, policy_revision: "v1")
  end
end
