require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @spec = create_document(title: "Visible feature", body: "Feature requirements")
    @project = @spec.project
    @user = User.create!(email_address: "spec-author@example.com", password: "password-123", password_confirmation: "password-123")
    sign_in_as(@user)
  end

  test "Specs shows only specifications and hides internal tracker routes" do
    tracker = create_document(project: @project, artifact_type: "plan_tracker", status: "tracking", title: "Internal execution tracker")
    get documents_path(project_id: @project.id)
    assert_response :success
    assert_select "h1", "Specs"
    assert_select "h2", text: @spec.title
    assert_select "h2", text: tracker.title, count: 0
    assert_select "a[data-turbo-frame='modal'][href='#{new_document_path(project_id: @project.id)}']", text: "New"
    assert_select "main form", count: 0
    assert_select "main select", count: 0
    assert_no_match(/Plan Trackers|New Draft|Document type navigation/, response.body)
    get document_path(tracker)
    assert_response :not_found
    get edit_document_path(tracker)
    assert_response :not_found
    post approve_document_path(tracker), params: {revision: tracker.source_hash}
    assert_response :not_found
  end

  test "New opens generation and manual authoring inside the modal" do
    use_case = create_use_case(project: @project, name: "Billing")
    get new_document_path(project_id: @project.id)
    assert_response :success
    assert_select "turbo-frame#modal [role='dialog']" do
      assert_select "form[action='#{generate_documents_path(project_id: @project.id)}']" do
        assert_select "select[name='use_case_id'] option[value='#{use_case.id}']", text: "Billing"
        assert_select "textarea[name='feature']"
      end
      assert_select "a[data-turbo-frame='modal']", text: "Write"
    end

    get new_document_path(project_id: @project.id, mode: "write")
    assert_response :success
    assert_select "turbo-frame#modal form[action='#{documents_path(project_id: @project.id)}']" do
      assert_select "select[name='document[use_case_id]']"
      assert_select "textarea[name='document[body]']"
      assert_select "button", text: "Save and approve"
    end
  end

  test "manual authoring and one click approval retain the same spec" do
    assert_difference "Document.count", 1 do
      post documents_path(project_id: @project.id), params: {document: {title: "Manual spec", body: "Detailed behavior"}, approval: "draft"}
    end
    assert_response :redirect
    created = @project.documents.order(:id).last
    assert_equal "draft", created.status
    assert_no_difference "Document.count" do
      post approve_document_path(created), params: {revision: created.source_hash}
    end
    assert_redirected_to document_path(created)
    assert_equal "approved", created.reload.status
    assert_equal "approved", created.source[:metadata]["status"]
  end

  test "save and approve needs no discovery artifacts" do
    post documents_path(project_id: @project.id), params: {document: {title: "Already understood", body: "Complete feature"}, approval: "approved"}
    assert_response :redirect
    assert_equal "approved", @project.documents.order(:id).last.status
    assert_equal 0, @project.quizzes.count
    assert_equal 0, @project.dumps.count
  end

  test "web editing rejects a stale file revision" do
    revision = @spec.source_hash
    path = Pathname.new(@project.root_path).join(@spec.relative_path)
    path.write(path.read + "\nOutside edit\n")
    patch document_path(@spec), params: {document: {title: "Old edit", body: "Outdated browser content", revision: revision}}
    assert_response :conflict
    assert_includes path.read, "Outside edit"
    assert_not_includes path.read, "Outdated browser content"
  end

  test "web generation calls the wrapped harness without manual document creation" do
    program = Pathname.new(@project.root_path).join("web-test-harness")
    program.write(<<~'SCRIPT')
      #!/usr/bin/env ruby
      require "json"
      context = JSON.parse(STDIN.read.split("Context:\n", 2).last)
      raise "wrong feature" unless context["feature"] == "Add invoice corrections"
      output = ARGV[ARGV.index("--output-last-message") + 1]
      File.write(output, JSON.generate({title: "Invoice corrections", body: "# Corrections\n\nPreserve invoice history."}))
    SCRIPT
    program.chmod(0o700)
    previous = ENV["REDWRIGHT_SPEC_HARNESS"]
    ENV["REDWRIGHT_SPEC_HARNESS"] = program.to_s
    assert_difference "Document.count", 1 do
      post generate_documents_path(project_id: @project.id), params: {feature: "Add invoice corrections"}
    end
    generated = @project.documents.order(:id).last
    assert_redirected_to document_path(generated)
    assert_equal "draft", generated.status
    assert_equal "Invoice corrections", generated.title
    assert_includes generated.body, "Preserve invoice history"
  ensure
    ENV["REDWRIGHT_SPEC_HARNESS"] = previous
  end

  test "direct spec creation rejects another projects use case" do
    foreign = create_use_case
    assert_no_difference "Document.count" do
      post documents_path(project_id: @project.id), params: {document: {title: "Invalid scope", body: "Content", use_case_id: foreign.id}}
    end
    assert_response :unprocessable_entity
    assert_select "turbo-frame#modal .document-artifact-errors"
    assert_select "textarea[name='document[body]']", text: "Content"
  end

  test "generation failure retains the modal inputs for retry" do
    use_case = create_use_case(project: @project, name: "Billing")
    previous = ENV["REDWRIGHT_SPEC_HARNESS"]
    ENV["REDWRIGHT_SPEC_HARNESS"] = File.join(@project.root_path, "missing-harness")
    assert_no_difference "Document.count" do
      post generate_documents_path(project_id: @project.id), params: {feature: "Keep invoice history", use_case_id: use_case.id}
    end
    assert_response :unprocessable_entity
    assert_select "turbo-frame#modal" do
      assert_select "[role='alert']", text: /harness is unavailable/
      assert_select "option[selected][value='#{use_case.id}']"
      assert_select "textarea[name='feature']", text: "Keep invoice history"
    end
  ensure
    ENV["REDWRIGHT_SPEC_HARNESS"] = previous
  end
end
