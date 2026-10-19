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

  test "separate processes share two call slots" do
    # Distinct projects and roles must contend for the same application-database capacity.
    records = [admit("one"), admit("two", purpose: "ticket_proposal")]
    other_project = create_project(name: "Other fixture", key: "other-fixture")
    records << Harnesses::Selection.new(project: other_project, store: @store).admit!(operation_key: "three",
      purpose: "specification", role: "authoring", schema: {}, policy_revision: "v1")
    results = harness_processes(3) do |index|
      lease = @lifecycle.start!(operation: records.fetch(index))
      {"operation_id" => lease.operation_id, "owner_token" => lease.owner_token}
    end
    assert_equal 2, results.count { |result| result["ok"] }
    assert_equal ["capacity"], results.reject { |result| result["ok"] }.map { |result| result["code"] }
    assert_equal 2, HarnessOperation.where(state: "running").count
    results.select { |result| result["ok"] }.each do |result|
      value = result.fetch("value")
      lease = Harnesses::Operation::Lease.new(operation_id: value.fetch("operation_id"), owner_token: value.fetch("owner_token"), binding: {}, resources: {})
      @lifecycle.finish!(lease: lease, outcome: "completed")
    end
    assert_equal 0, HarnessOperation.where(state: "running").count
  end

  test "retention preserves references and uncertain operations" do
    # Capacity reclamation is limited to terminal, unreferenced operations older than thirty days.
    seed = admit("seed")
    template = seed.attributes.except("id")
    rows = 1023.times.map do |index|
      values = template.merge("operation_key" => "existing-#{index}", "private_run_ref" => SecureRandom.uuid)
      binding = seed.binding.merge("operation_id" => values.fetch("operation_key"))
      values.merge("binding_json" => Harnesses::CanonicalJson.dump(binding), "binding_digest" => Harnesses::CanonicalJson.digest(binding))
    end
    HarnessOperation.insert_all!(rows)
    assert_equal :capacity, assert_raises(Harnesses::Error) { admit("full") }.code
    seed.update!(state: "failed", finished_at: 31.days.ago)
    referenced = HarnessOperation.find_by!(operation_key: "existing-0")
    referenced.update!(state: "completed", finished_at: 31.days.ago,
      attempts_json: JSON.generate([{number: 1, state: "completed", owner_digest: "b" * 64, started_at: 31.days.ago.iso8601, artifact_ref: "spec/retained"}]))
    uncertain = HarnessOperation.find_by!(operation_key: "existing-1")
    uncertain.update!(state: "uncertain", finished_at: 31.days.ago)
    assert_equal "replacement", admit("replacement").operation_key
    assert_equal 1024, HarnessOperation.count
    assert_not HarnessOperation.exists?(seed.id)
    assert HarnessOperation.exists?(referenced.id)
    assert HarnessOperation.exists?(uncertain.id)
    assert_raises(Harnesses::Error) { @store.read(seed.private_run_ref) }
    assert_equal :capacity, assert_raises(Harnesses::Error) { admit("still-full") }.code
  end

  test "damaged bindings cannot acquire a call slot" do
    # Even a matching checksum cannot make an incomplete mandatory format executable.
    record = admit("damaged")
    original = record.binding
    cases = {
      "unknown format" => original.merge("schema_version" => "harness-binding/v2"),
      "missing harness" => original.except("harness"),
      "changed purpose" => original.merge("purpose" => "ticket_proposal")
    }
    cases.each do |name, value|
      bytes = Harnesses::CanonicalJson.dump(value)
      HarnessOperation.where(id: record.id).update_all(binding_json: bytes, binding_digest: Digest::SHA256.hexdigest(bytes))
      assert_equal :invalid_binding, assert_raises(Harnesses::Error, name) { @lifecycle.start!(operation: record) }.code
      assert_equal "prepared", record.reload.state, name
      assert_empty record.attempts, name
    end
  end

  private

  def admit(key, purpose: "specification")
    @selection.admit!(operation_key: key, purpose: purpose, role: purpose == "ticket_proposal" ? "ticket_proposal" : "authoring", schema: {}, policy_revision: "v1")
  end
end
