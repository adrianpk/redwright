require "test_helper"

class ProjectDumpsControllerTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "dump-owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  test "index requires authentication" do
    project = create_project(key: "dump-controller-auth")

    get project_dumps_path(project)

    assert_redirected_to new_session_path
  end

  test "top navigation lists dumps before quizzes" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "dump-controller-navigation")

    [project_dumps_path(project), project_quizzes_path(project)].each do |path|
      get path

      assert_response :success
      assert_select ".top-nav-link[href='#{project_dumps_path(project)}']", text: "Dumps"
      assert_select ".top-nav-link[href='#{project_quizzes_path(project)}']", text: "Quizzes"
      assert_select ".top-nav-link", text: "Conv", count: 0
      labels = css_select(".top-nav-link").map(&:text)
      assert_operator labels.index("Dumps"), :<, labels.index("Quizzes")
    end
  end

  test "index renders dumps and use case start actions" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(name: "Dump Web Project", key: "dump-controller-index")
    use_case = create_use_case(project: project, name: "Billing")
    available = create_use_case(project: project, name: "Checkout")
    dump = project.dumps.create!(use_case: use_case, title: "Billing Dump")
    dump.entries.create!(raw_input: "raw", polished_input: "Polished billing note.")

    get project_dumps_path(project)

    assert_response :success
    assert_match "Dumps", response.body
    assert_match "Project: Dump Web Project", response.body
    assert_select ".artifact-type-card h2", text: "Billing Dump"
    assert_select "a[data-turbo-frame='modal'][href='#{new_project_dump_path(project)}']", text: "New"
    assert_select "main select", count: 0
    assert_match "Polished billing note.", response.body
    get new_project_dump_path(project)
    assert_select "turbo-frame#modal select option", text: available.name
    assert_select "turbo-frame#modal select option", text: use_case.name, count: 0
  end

  test "creates project and use case dumps" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "dump-controller-create")
    create_use_case(project: project, name: "Checkout")

    post project_dumps_path(project)

    project_dump = project.dumps.order(:id).last
    assert_redirected_to project_dump_path(project, project_dump)
    assert_nil project_dump.use_case_id

    post project_dumps_path(project), params: { use_case_name: "Checkout" }

    use_case_dump = project.dumps.order(:id).last
    assert_redirected_to project_dump_path(project, use_case_dump)
    assert_equal "Checkout", use_case_dump.use_case.name
  end

  test "show appends entries and renders raw preview" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "dump-controller-append")
    dump = project.dumps.create!(title: "Project Dump")

    get project_dump_path(project, dump)

    assert_response :success
    assert_select ".document-artifact-breadcrumb a[href='#{project_dumps_path(project)}']", text: "Dumps"
    assert_select "#dump-entry-form textarea[name='raw_input']"
    assert_select "button", text: "Add Entry"

    post append_project_dump_path(project, dump), params: { raw_input: "Keep dump posts brief." }

    assert_redirected_to project_dump_path(project, dump)
    follow_redirect!
    assert_response :success
    assert_match "Keep dump posts brief.", response.body
    assert_equal 1, dump.entries.count
  end

  test "done closes and curates while cancel closes without deleting entries" do
    admin = create_admin_user!
    sign_in_as(admin)
    done_project = create_project(key: "dump-controller-done")
    done_dump = done_project.dumps.create!(title: "Done Dump")
    done_dump.entries.create!(raw_input: "first", polished_input: "First.")

    post done_project_dump_path(done_project, done_dump)

    assert_redirected_to project_dump_path(done_project, done_dump)
    assert_equal "completed", done_dump.reload.status
    assert_equal "closed", done_dump.capture_status
    assert done_dump.curated_body.present?

    cancel_project = create_project(key: "dump-controller-cancel")
    cancel_dump = cancel_project.dumps.create!(title: "Cancel Dump")
    cancel_dump.entries.create!(raw_input: "first", polished_input: "First.")

    post cancel_project_dump_path(cancel_project, cancel_dump)

    assert_redirected_to project_dumps_path(cancel_project)
    assert_equal "cancelled", cancel_dump.reload.status
    assert_equal "closed", cancel_dump.capture_status
    assert_equal 1, cancel_dump.entries.count
  end

  test "curates closed dump" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "dump-controller-curate")
    dump = project.dumps.create!(title: "Curate Dump", status: "completed", capture_status: "closed")
    dump.entries.create!(raw_input: "first", polished_input: "First.")

    post curate_project_dump_path(project, dump)

    assert_redirected_to project_dump_path(project, dump)
    assert dump.reload.curated_body.present?
  end
end
