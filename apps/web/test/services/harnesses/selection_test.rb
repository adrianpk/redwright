require "test_helper"
require_relative "../../support/harness_database_fixture"

class HarnessesSelectionTest < ActiveSupport::TestCase
  include HarnessDatabaseFixture

  setup do
    @project = create_project
    @actor = User.create!(email_address: "operator@example.test", password: "password-123")
    @profiles_path = File.join(@harness_fixture_root, "profiles.json")
    profiles = %w[blue green].map { |name| {name: name, harness: "codex", executable_ref: "/bin/true",
      requested_model: "#{name}-model", capabilities: {structured_output: true}} }
    File.write(@profiles_path, JSON.generate(version: 1, profiles: profiles), perm: 0o600)
    @now = Time.current
    @store = Harnesses::BindingStore.new(directory: File.join(@harness_fixture_root, "bindings"))
    @selection = Harnesses::Selection.new(project: @project, registry: Harnesses::ProfileRegistry.new(path: @profiles_path), store: @store, clock: -> { @now })
  end

  test "selection retries preserve one coherent revision" do
    # An exact retry returns its original result even after a later independent change.
    first = @selection.change!(actor: @actor, request_id: "first", expected_revision: 0, changes: {authoring_profile: "blue"})
    assert_equal 1, first.fetch("revision")
    second = @selection.change!(actor: @actor, request_id: "second", expected_revision: 1, changes: {ticket_proposal_profile: "green"})
    assert_equal "blue", second.fetch("authoring_profile")
    assert_equal "green", second.fetch("ticket_proposal_profile")
    assert_equal first, @selection.change!(actor: @actor, request_id: "first", expected_revision: 0, changes: {authoring_profile: "blue"})
    assert_equal 2, @selection.current.fetch("revision")
    error = assert_raises(Harnesses::Error) do
      @selection.change!(actor: @actor, request_id: "first", expected_revision: 0, changes: {authoring_profile: "green"})
    end
    assert_equal :conflict, error.code
    error = assert_raises(Harnesses::Error) do
      @selection.change!(actor: @actor, request_id: "stale", expected_revision: 0, changes: {authoring_profile: nil})
    end
    assert_equal :stale_revision, error.code
    cleared = @selection.change!(actor: @actor, request_id: "clear", expected_revision: 2, changes: {authoring_profile: nil})
    assert_nil cleared.fetch("authoring_profile")
    assert_equal "green", cleared.fetch("ticket_proposal_profile")
    assert_equal @actor.id, ProjectHarnessSetting.find_by!(project: @project).changed_by_id
    projection = ProjectHarnessSetting.find_by!(project: @project).to_json
    assert_not_includes projection, "receipts"
    assert_not_includes projection, @harness_fixture_root
  end

  test "invalid selections do not publish changes" do
    # Authentication, readiness and field allowlists precede the settings mutation.
    cases = {
      "unauthenticated" => [{actor: nil, changes: {authoring_profile: "blue"}}, :unauthorized],
      "unknown profile" => [{changes: {authoring_profile: "missing"}}, :unknown_profile],
      "executable input" => [{changes: {executable_ref: "/bin/true"}}, :invalid_request]
    }
    cases.each do |name, (overrides, code)|
      args = {actor: @actor, request_id: name, expected_revision: 0, changes: {authoring_profile: "blue"}}.merge(overrides)
      assert_equal code, assert_raises(Harnesses::Error, name) { @selection.change!(**args) }.code
      assert_equal 0, @selection.current.fetch("revision"), name
      assert_nil @selection.current.fetch("authoring_profile"), name
    end
  end

  test "operations retain bindings across selection changes" do
    # Existing logical operations never re-resolve defaults or private profile references.
    @selection.change!(actor: @actor, request_id: "blue", expected_revision: 0, changes: {authoring_profile: "blue"})
    args = {operation_key: "spec-one", purpose: "specification", role: "authoring", schema: {type: "object"}, policy_revision: "v1"}
    first = @selection.admit!(**args)
    original = first.binding_json
    assert_equal "blue", first.binding.fetch("profile")
    assert first.binding.frozen?
    @selection.change!(actor: @actor, request_id: "green", expected_revision: 1, changes: {authoring_profile: "green"})
    later = @selection.admit!(**args.merge(operation_key: "spec-two"))
    assert_equal "green", later.binding.fetch("profile")
    File.unlink(@profiles_path)
    retained = @selection.admit!(**args)
    assert_equal first.id, retained.id
    assert_equal original, retained.binding_json
    assert_equal :conflict, assert_raises(Harnesses::Error) { @selection.admit!(**args.merge(policy_revision: "v2")) }.code
    assert_equal :conflict, assert_raises(Harnesses::Error) { @selection.admit!(**args.merge(workspace_revision: {base: "changed"})) }.code
    assert_not_includes first.to_json, @harness_fixture_root
    assert_not_includes first.to_json, "executable_ref"
    assert_raises(ActiveRecord::ActiveRecordError) { first.update_column(:binding_json, "{}") }
  end

  test "legacy roles keep their distinct defaults" do
    # Admission snapshots the existing executable overrides and preserves the direct API role.
    previous = ENV["REDWRIGHT_SPEC_HARNESS"]
    ENV["REDWRIGHT_SPEC_HARNESS"] = "/fixture/codex-compatible"
    authoring = @selection.admit!(operation_key: "legacy-spec", purpose: "specification", role: "authoring", schema: {}, policy_revision: "v1")
    ticket = @selection.admit!(operation_key: "legacy-ticket", purpose: "ticket_proposal", role: "ticket_proposal", schema: {}, policy_revision: "v1")
    assert_equal "codex", authoring.binding.fetch("harness")
    assert_equal "direct_api", ticket.binding.fetch("harness")
    assert_equal "legacy_default", authoring.binding.fetch("selection_source")
    assert_equal "/fixture/codex-compatible", @store.read(authoring.private_run_ref).fetch("executable_ref")
    assert_equal({}, @store.read(ticket.private_run_ref))
    assert_nil ProjectHarnessSetting.find_by(project: @project)
  ensure
    ENV["REDWRIGHT_SPEC_HARNESS"] = previous
  end

  test "separate processes serialize selection races" do
    # Both writers start from revision zero; exactly one complete image can win.
    results = harness_processes(2) do |index|
      key = %w[blue green].fetch(index)
      @selection.change!(actor: @actor, request_id: "race-#{index}", expected_revision: 0,
        changes: {authoring_profile: key, ticket_proposal_profile: key})
    end
    assert_equal 1, results.count { |result| result["ok"] }
    assert_equal ["stale_revision"], results.reject { |result| result["ok"] }.map { |result| result["code"] }
    image = @selection.current
    assert_equal 1, image.fetch("revision")
    assert_equal image.fetch("authoring_profile"), image.fetch("ticket_proposal_profile")
    assert_equal 1, ProjectHarnessSetting.where(project: @project).count
  end

  test "admission races retain a complete settings image" do
    # A concurrent admission observes either the old image or the new image with its matching revision.
    @selection.change!(actor: @actor, request_id: "initial", expected_revision: 0, changes: {authoring_profile: "blue"})
    old = @selection.admit!(operation_key: "old", purpose: "specification", role: "authoring", schema: {}, policy_revision: "v1")
    results = harness_processes(2) do |index|
      if index.zero?
        @selection.change!(actor: @actor, request_id: "switch", expected_revision: 1, changes: {authoring_profile: "green"})
      else
        record = @selection.admit!(operation_key: "racing", purpose: "specification", role: "authoring", schema: {}, policy_revision: "v1")
        record.binding.slice("profile", "selection_revision")
      end
    end
    assert results.all? { |result| result["ok"] }
    assert_includes [{"profile" => "blue", "selection_revision" => 1}, {"profile" => "green", "selection_revision" => 2}], results.last.fetch("value")
    latest = @selection.admit!(operation_key: "latest", purpose: "specification", role: "authoring", schema: {}, policy_revision: "v1")
    assert_equal "green", latest.binding.fetch("profile")
    assert_equal 2, latest.selection_revision
    assert_equal "blue", old.reload.binding.fetch("profile")
  end

  test "receipt capacity and expiry prevent stale replay" do
    # Expiration can free capacity, but it cannot restore an old request's revision authority.
    first = @selection.change!(actor: @actor, request_id: "original", expected_revision: 0, changes: {authoring_profile: "blue"})
    127.times do |index|
      @selection.change!(actor: @actor, request_id: "fill-#{index}", expected_revision: index + 1, changes: {authoring_profile: "green"})
    end
    setting = ProjectHarnessSetting.find_by!(project: @project)
    assert_equal 128, setting.receipts.size
    assert_equal first, @selection.change!(actor: @actor, request_id: "original", expected_revision: 0, changes: {authoring_profile: "blue"})
    assert_equal :capacity, assert_raises(Harnesses::Error) { @selection.change!(actor: @actor, request_id: "overflow", expected_revision: 128, changes: {authoring_profile: "blue"}) }.code
    assert_equal 128, @selection.current.fetch("revision")
    @now += 8.days
    assert_equal :stale_revision, assert_raises(Harnesses::Error) { @selection.change!(actor: @actor, request_id: "original", expected_revision: 0, changes: {authoring_profile: "blue"}) }.code
    fresh = @selection.change!(actor: @actor, request_id: "fresh", expected_revision: 128, changes: {authoring_profile: nil})
    assert_equal 129, fresh.fetch("revision")
    assert_equal 1, setting.reload.receipts.size
    assert_nil fresh.fetch("authoring_profile")
  end


  test "profiles expose semantic identity and private references separately" do
    # Resolution performs local checks without reading credential bytes or invoking a model.
    Dir.mktmpdir("harness-profiles-") do |root|
      credential = File.join(root, "credential.json")
      File.write(credential, "private credential fixture", perm: 0o600)
      path = File.join(root, "profiles.json")
      profile = {name: "local", harness: "codex", executable_ref: "/bin/true", credential_ref: credential,
        capabilities: {structured_output: true}}
      File.write(path, JSON.generate(version: 1, profiles: [profile]), perm: 0o600)
      registry = Harnesses::ProfileRegistry.new(path: path)
      resolved = registry.resolve("local").ready!
      assert_equal credential, resolved.private_values.fetch("credential_ref")
      assert_equal 64, resolved.public_values.fetch("revision").size
      assert_not_includes resolved.public_values.to_json, root
      assert_not_includes resolved.public_values.to_json, "private credential fixture"
      profile[:requested_model] = "next-model"
      File.write(path, JSON.generate(version: 1, profiles: [profile]))
      assert_not_equal resolved.public_values["revision"], registry.resolve("local").public_values["revision"]
      assert_equal :unknown_profile, assert_raises(Harnesses::Error) { registry.resolve("missing") }.code
      File.chmod(0o644, path)
      assert_equal :invalid_profile, assert_raises(Harnesses::Error) { registry.resolve("local") }.code
    end
  end

  test "profiles reject unsupported adapters and unsafe files" do
    # Private configuration cannot silently become another backend or expose a symlink target.
    Dir.mktmpdir("harness-profiles-") do |root|
      path = File.join(root, "profiles.json")
      cases = {
        "unsupported harness" => [{name: "local", harness: "other", executable_ref: "/bin/true"}],
        "raw credential" => [{name: "local", harness: "codex", executable_ref: "/bin/true", api_key: "fixture"}],
        "too many profiles" => Array.new(65) { |index| {name: "local-#{index}", harness: "codex", executable_ref: "/bin/true"} }
      }
      cases.each do |name, profiles|
        File.write(path, JSON.generate(version: 1, profiles: profiles), perm: 0o600)
        assert_equal :invalid_profile, assert_raises(Harnesses::Error, name) { Harnesses::ProfileRegistry.new(path: path).resolve("local") }.code
      end
      File.symlink(path, File.join(root, "link.json"))
      assert_equal :invalid_profile, assert_raises(Harnesses::Error) { Harnesses::ProfileRegistry.new(path: File.join(root, "link.json")).resolve("local") }.code
      File.write(path, JSON.generate(version: 1, profiles: [{name: "local", harness: "pi", executable_ref: "/bin/true",
        protocol_revision: "1.3.0", requested_model: "model", requested_provider: "provider", capabilities: {structured_output: true}}]))
      assert_equal :unsupported_capability, assert_raises(Harnesses::Error) { Harnesses::ProfileRegistry.new(path: path).resolve("local").ready! }.code
    end
  end
end
