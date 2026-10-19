require "test_helper"
require_relative "../support/harness_database_fixture"

class ProjectHarnessSettingsControllerTest < ActionDispatch::IntegrationTest
  include HarnessDatabaseFixture
  setup do
    @project = create_project
    @user = User.create!(email_address: "profile-owner@example.test", password: "password-123")
    @root = Dir.mktmpdir("harness-page-")
    @protocol_test_directories << @root
    @marker = File.join(@root, "invoked")
    program = File.join(@root, "prepared-program")
    File.write(program, "#!/bin/sh\nprintf invoked > #{@marker.dump}\n")
    File.chmod(0o700, program)
    credential = File.join(@root, "credential.json")
    File.write(credential, "PRIVATE_RESOURCE_SENTINEL", perm: 0o600)
    @profiles = %w[blue green].map { |name| {name: name, harness: "codex", executable_ref: program, credential_ref: credential,
      requested_provider: "fixture-provider", requested_model: "#{name}-model", capabilities: {structured_output: true}} }
    write_profiles
    sign_in_as(@user)
  end

  test "the page exposes choices and local readiness safely" do
    # Real HTML rendering must expose usable profile controls while hiding private paths, credentials and launch inputs.
    get project_harness_setting_path(@project)
    assert_response :success
    assert_select "h1", "Harness"
    assert_select "a[href='#{project_harness_setting_path(@project)}']", text: "Harness"
    assert_select "form[action='#{project_harness_setting_path(@project)}']", count: 2
    assert_select "label[for='harness-authoring']", text: "Authoring"
    assert_select "label[for='harness-ticket_proposal']", text: "Ticket proposals"
    assert_select "select[name='harness_setting[authoring_profile]'] option[value='blue']"
    assert_select "select[name='harness_setting[ticket_proposal_profile]'] option[value='']", text: "Use Direct API default"
    assert_select "input[name='harness_setting[request_id]']", count: 2
    assert_select "input[name*='executable'], input[name*='credential'], input[name*='model_config']", count: 0
    assert_includes response.body, "Available locally"
    assert_includes response.body, "No active harness operations."
    assert_private_projection
    assert_not File.exist?(@marker)
    if ENV["REDWRIGHT_HARNESS_VIEWPORT"] == "1"
      # Opt-in exercises the actual compiled layout in an owned Chromium profile, without another app server.
      Dir.mktmpdir("harness-viewport-") do |root|
        File.write(File.join(root, "page.html"), response.body, perm: 0o600)
        result = Harnesses::ProcessSupervisor.new(stdout_limit: 8192, stderr_limit: 8192).run(
          command: ["node", Rails.root.join("test/support/harness_viewport_fixture.mjs").to_s, root],
          workspace: Rails.root.to_s, deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 20,
          capture_stdout: 8192)
        assert result.status.success?, "Owned viewport check failed: #{result.diagnostics.to_json}"
      end
    end
  end

  test "profile changes and clears use coherent retry receipts" do
    # HTTP retries reuse the same response; an explicit clear restores the role default without changing the other role.
    values = {authoring_profile: "blue", expected_revision: 0, request_id: "first-choice"}
    patch project_harness_setting_path(@project), params: {harness_setting: values}, as: :json
    assert_response :success
    first = response.parsed_body
    assert_equal "blue", first.fetch("authoring_profile")
    assert_equal 1, first.fetch("revision")
    patch project_harness_setting_path(@project), params: {harness_setting: values}, as: :json
    assert_response :success
    assert_equal first, response.parsed_body
    patch project_harness_setting_path(@project), params: {harness_setting: {ticket_proposal_profile: "green", expected_revision: 1, request_id: "ticket-choice"}}, as: :json
    assert_response :success
    patch project_harness_setting_path(@project), params: {harness_setting: {authoring_profile: "", expected_revision: 2, request_id: "clear-authoring"}}, as: :json
    assert_response :success
    assert_nil response.parsed_body["authoring_profile"]
    assert_equal "green", response.parsed_body["ticket_proposal_profile"]
    assert_equal @user.id, ProjectHarnessSetting.find_by!(project: @project).changed_by_id
    assert_not File.exist?(@marker)
  end

  test "local unavailability is visible and cannot be selected" do
    # An unusable profile remains explainable; showing readiness does not install or execute it.
    @profiles.first[:executable_ref] = File.join(@root, "missing")
    write_profiles
    get project_harness_setting_path(@project), as: :json
    assert_response :success
    blue = response.parsed_body.fetch("profiles").find { |row| row["name"] == "blue" }
    assert_equal false, blue.fetch("ready")
    assert_equal "unavailable", blue.fetch("readiness_code")
    assert_private_projection
    patch project_harness_setting_path(@project), params: {harness_setting: {authoring_profile: "blue", expected_revision: 0, request_id: "unavailable"}}, as: :json
    assert_response :unprocessable_entity
    assert_equal "unavailable", response.parsed_body.fetch("error")
    assert_nil ProjectHarnessSetting.find_by(project: @project)
    assert_not File.exist?(@marker)
  end

  test "active bindings remain distinct from saved defaults" do
    # Changing a default never rewrites an admitted operation or exposes its ownership token/private resource reference.
    selection = Harnesses::Selection.new(project: @project)
    selection.change!(actor: @user, request_id: "blue", expected_revision: 0, changes: {authoring_profile: "blue"})
    operation = selection.admit!(operation_key: "active-fixture", purpose: "specification", role: "authoring", schema: {}, policy_revision: "fixture/v1")
    lease = Harnesses::Operation.new.start!(operation: operation)
    selection.change!(actor: @user, request_id: "green", expected_revision: 1, changes: {authoring_profile: "green"})
    get project_harness_setting_path(@project)
    assert_response :success
    assert_select "select#harness-authoring option[selected][value='green']"
    assert_select "[data-harness-active]", text: /blue/
    assert_select "[data-harness-active]", text: /Specification · Running/
    assert_not_includes response.body, lease.owner_token
    assert_not_includes response.body, operation.private_run_ref
    assert_private_projection
    assert_not File.exist?(@marker)
  end

  test "authentication precedes reads and mutations" do
    # The same existing session boundary protects HTML, JSON and updates.
    delete session_path
    get project_harness_setting_path(@project)
    assert_redirected_to new_session_path
    assert_no_difference "ProjectHarnessSetting.count" do
      patch project_harness_setting_path(@project), params: {harness_setting: {authoring_profile: "blue", expected_revision: 0, request_id: "anonymous"}}, as: :json
    end
    assert_redirected_to new_session_path
    assert_not File.exist?(@marker)
  end

  test "stale requests and changed retries cannot overwrite selections" do
    # One saved revision wins; a request identity cannot be reused with different intent.
    values = {authoring_profile: "blue", expected_revision: 0, request_id: "saved"}
    patch project_harness_setting_path(@project), params: {harness_setting: values}, as: :json
    assert_response :success
    {"conflict" => values.merge(authoring_profile: "green"),
      "stale_revision" => values.merge(request_id: "stale", authoring_profile: "green")}.each do |code, attributes|
      patch project_harness_setting_path(@project), params: {harness_setting: attributes}, as: :json
      assert_response :conflict
      assert_equal code, response.parsed_body.fetch("error")
    end
    assert_equal "blue", ProjectHarnessSetting.find_by!(project: @project).authoring_profile
    assert_equal 1, ProjectHarnessSetting.find_by!(project: @project).lock_version
  end

  test "invalid web inputs never gain configuration authority" do
    # Strong parameters and service validation reject paths, unknown profile keys and malformed metadata before mutation.
    base = {authoring_profile: "blue", expected_revision: 0, request_id: "invalid"}
    cases = {"executable" => base.merge(executable_ref: "/bin/true"), "credential" => base.merge(credential_ref: "/private/auth"),
      "revision" => base.merge(expected_revision: "1x"), "unknown" => base.merge(authoring_profile: "missing"),
      "array" => base.merge(authoring_profile: ["blue"]), "project" => base.merge(project_id: @project.id)}
    cases.each do |name, attributes|
      assert_no_difference "ProjectHarnessSetting.count", name do
        patch project_harness_setting_path(@project), params: {harness_setting: attributes}, as: :json
      end
      assert_response :unprocessable_entity
      assert_private_projection
    end
    patch project_harness_setting_path(@project), params: {}, as: :json
    assert_response :unprocessable_entity
    assert_not File.exist?(@marker)
  end

  test "a separate web process changes the next request" do
    # An owned SQLite database and a second authenticated Rails session prove that no in-process selection cache owns state.
    get project_harness_setting_path(@project), as: :json
    assert_nil response.parsed_body.dig("selection", "authoring_profile")
    results = harness_processes(1) do |_index|
      client = ActionDispatch::Integration::Session.new(Rails.application)
      client.post(session_path, params: {email_address: @user.email_address, password: "password-123"})
      client.patch(project_harness_setting_path(@project), params: {harness_setting: {authoring_profile: "blue", expected_revision: 0, request_id: "other-process"}}, as: :json)
      {"status" => client.response.status, "body" => client.response.parsed_body}
    end
    assert_equal 200, results.sole.dig("value", "status")
    get project_harness_setting_path(@project), as: :json
    assert_equal "blue", response.parsed_body.dig("selection", "authoring_profile")
    assert_equal 1, response.parsed_body.dig("selection", "revision")
    assert_private_projection
    assert_not File.exist?(@marker)
  end

  private

  def write_profiles
    File.write(ENV.fetch("REDWRIGHT_HARNESS_PROFILES"), JSON.generate(version: 1, profiles: @profiles), perm: 0o600)
  end

  def assert_private_projection
    assert_not_includes response.body, @root
    assert_not_includes response.body, "PRIVATE_RESOURCE_SENTINEL"
  end
end
