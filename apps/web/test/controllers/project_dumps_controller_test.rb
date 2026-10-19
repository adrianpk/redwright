require "test_helper"

class ProjectDumpsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = create_project
    @user = User.create!(email_address: "dump-owner@example.com", password: "password-123", password_confirmation: "password-123")
  end

  test "requires authentication" do
    get project_dumps_path(@project)
    assert_redirected_to new_session_path
  end

  test "lists one card per document and chooses the case in New" do
    sign_in_as(@user)
    feature = create_use_case(project: @project)
    available = create_use_case(project: @project, name: "Checkout")
    dump = @project.dumps.create!(use_case: feature, body: "Current notes")
    get project_dumps_path(@project)
    assert_response :success
    assert_select ".artifact-type-card", count: 1
    assert_select ".artifact-type-card h2", text: feature.name
    assert_select ".protocol-card-preview", text: "Current notes"
    assert_select "main select", count: 0
    assert_select "a[data-turbo-frame='modal']", text: "New"
    assert_select ".top-nav-link[aria-current='page']", text: "Dumps", count: 1
    labels = css_select(".top-nav-link").map(&:text)
    assert_operator labels.index("Dumps"), :<, labels.index("Quizzes")
    get new_project_dump_path(@project)
    assert_select "select option", text: available.name
    assert_select "select option", text: feature.name, count: 0
    post project_dumps_path(@project), params: {use_case_name: feature.name}
    assert_redirected_to project_dump_path(@project, dump)
    assert_equal 1, @project.dumps.count
  end

  test "shows one rendered editable document and one status" do
    sign_in_as(@user)
    dump = @project.dumps.create!(body: "# Notes\n\n**Decision**\n\n<script>alert(1)</script>")
    get project_dump_path(@project, dump)
    assert_response :success
    assert_select ".top-nav-link[aria-current='page']", text: "Dumps", count: 1
    assert_select "[data-dump-view] h1", text: "Notes"
    assert_select "[data-dump-view] strong", text: "Decision"
    assert_select "[data-dump-view] script", count: 0
    assert_select ".artifact-metadata dt", text: "Status", count: 1
    assert_select ".artifact-metadata dd", text: "Draft", count: 1
    assert_select "form[data-dump-editor][hidden] textarea[name='dump[body]']", count: 1
    assert_select "#dump-entry-form, .artifact-type-card", count: 0
    assert_select "button", text: /Resume|Add Entry|Done|Cancel/, count: 0
  end

  test "updates whole file and rejects stale saves without losing external edits" do
    sign_in_as(@user)
    dump = @project.dumps.create!(body: "Initial")
    original = dump.source_hash
    patch project_dump_path(@project, dump), params: {dump: {body: "Replacement", revision: original, status: "ready"}}, as: :json
    assert_response :success
    assert_equal "Replacement", dump.source[:body]
    assert_equal "ready", dump.reload.status
    assert_equal "<p>Replacement</p>\n", response.parsed_body["rendered_body"]
    patch project_dump_path(@project, dump), params: {dump: {body: "Stale", revision: original}}, as: :json
    assert_response :conflict
    assert_equal "Replacement", dump.source[:body]
    patch project_dump_path(@project, dump), params: {dump: {body: "Bad", revision: dump.source_hash, status: "closed"}}, as: :json
    assert_response :unprocessable_entity
    assert_equal "Replacement", dump.source[:body]
  end

  test "cannot read or update another project dump" do
    sign_in_as(@user)
    other = create_project(key: "other")
    dump = other.dumps.create!(body: "Private")
    get project_dump_path(@project, dump)
    assert_response :not_found
    patch project_dump_path(@project, dump), params: {dump: {body: "Changed", revision: dump.source_hash}}, as: :json
    assert_response :not_found
    assert_equal "Private", dump.body
  end
end
