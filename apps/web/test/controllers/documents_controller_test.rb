require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    feature = create_use_case(name: "Visible feature")
    @spec = create_document(project: feature.project, use_case: feature, title: "Visible feature Spec",
      body: "# Visible feature Spec\n\n## Requirements\n\n- Keep **decisions**.\n\n<script>alert(1)</script>")
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
    assert_select ".artifact-type-card p", count: 0
    assert_select ".artifact-type-card .protocol-card-preview", count: 1
    assert_select "a[data-turbo-frame='modal'][href='#{new_document_path(project_id: @project.id)}']", text: "New"
    assert_select "main form", count: 0
    assert_select "main select", count: 0
    assert_no_match(/Plan Trackers|New Draft|Document type navigation/, response.body)
    get document_path(@spec)
    assert_response :success
    assert_select ".artifact-title-row h1", text: @spec.title
    assert_select "[data-artifact-status-control] legend", text: "Specification status"
    assert_select "[data-artifact-status-option][checked]", value: @spec.status, count: 1
    assert_select "[data-spec-view][role='button']"
    assert_select "a", text: "Edit", count: 0
    assert_select "form[data-spec-editor][hidden] textarea[name='document[body]']"
    assert_select ".document-artifacts-header .board-key, .artifact-context-label", count: 0
    assert_select "article h2", text: "Requirements"
    assert_select "article strong", text: "decisions"
    assert_select "article > pre, article script", count: 0
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
      assert_select "button", text: "Save"
      assert_select "input[name='approval'][value='draft'][checked]"
      assert_select "input[name='approval'][value='approved']"
    end
  end

  test "manual authoring and one click approval retain the same spec" do
    use_case = create_use_case(project: @project, name: "Manual feature")
    assert_difference "Document.count", 1 do
      post documents_path(project_id: @project.id), params: {document: {title: "Manual spec", body: "Detailed behavior", use_case_id: use_case.id}, approval: "draft"}
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
    use_case = create_use_case(project: @project, name: "Already understood")
    post documents_path(project_id: @project.id), params: {document: {title: "Already understood", body: "Complete feature", use_case_id: use_case.id}, approval: "approved"}
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

  test "inline saves persist Markdown and approval and reject stale or invalid content" do
    original = @spec.source_hash
    patch document_path(@spec), params: {document: {body: "# Revised\n\n**Decision**", revision: original}, approval: "approved"}, as: :json
    assert_response :success
    assert_equal "approved", @spec.reload.status
    assert_includes response.parsed_body["rendered_body"], "<strong>Decision</strong>"
    assert_equal @spec.source_hash, response.parsed_body["revision"]
    revision = @spec.source_hash
    patch document_path(@spec), params: {document: {body: "Stale", revision: original}, approval: "draft"}, as: :json
    assert_response :conflict
    assert response.parsed_body["errors"].any?
    patch document_path(@spec), params: {document: {body: "", revision: revision}, approval: "draft"}, as: :json
    assert_response :unprocessable_entity
    assert_includes @spec.source[:body], "**Decision**"
    patch document_path(@spec), params: {document: {body: @spec.source[:body], revision: revision}, approval: "draft"}, as: :json
    assert_response :success
    assert_equal "draft", @spec.reload.status
  end

  test "web generation calls the wrapped harness without manual document creation" do
    use_case = create_use_case(project: @project, name: "Invoice corrections")
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
      post generate_documents_path(project_id: @project.id), params: {feature: "Add invoice corrections", use_case_id: use_case.id}
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

  test "the web regenerates and slices one feature until execution begins" do
    # Exercise the actual form endpoints and subprocess contract without a live model.
    board = create_board(project: @project)
    ready = board.columns.create!(key: "backlog", title: "Ready", position: 0)
    working = board.columns.create!(key: "in_progress", title: "Working", position: 1)
    program = Pathname.new(@project.root_path).join("feature-web-harness")
    program.write(<<~'SCRIPT')
      #!/usr/bin/env ruby
      require "json"
      context = JSON.parse(STDIN.read.split("Context:\n", 2).last)
      result = if context.key?("existing_tickets")
        {tickets: [{key: nil, title: "Implement feature", body: "Scope and acceptance criteria"}]}
      else
        {title: "Updated feature", body: "# Updated contract\n\nLatest discovery."}
      end
      File.write(ARGV[ARGV.index("--output-last-message") + 1], JSON.generate(result))
    SCRIPT
    program.chmod(0o700)
    previous = ENV["REDWRIGHT_SPEC_HARNESS"]
    ENV["REDWRIGHT_SPEC_HARNESS"] = program.to_s
    assert_no_difference "Document.specifications.count" do
      post regenerate_document_path(@spec)
      assert_redirected_to document_path(@spec)
    end
    @spec.reload
    post approve_document_path(@spec), params: {revision: @spec.source_hash}
    assert_difference "Ticket.count", 1 do
      post slice_document_path(@spec)
      assert_redirected_to document_path(@spec)
    end
    ticket = board.tickets.find_by!(title: "Implement feature")
    assert_equal ready.id, ticket.column_id
    ticket.transition_to_column!(working)
    get document_path(@spec)
    assert_response :success
    assert_select "button", text: "Regenerate", count: 0
    assert_select "a", text: "New corrective case"
    assert_select "[data-spec-view][role='button'], [data-spec-editor]", count: 0
    assert_select "[data-artifact-status-control][disabled]"
    post regenerate_document_path(@spec)
    assert_response :unprocessable_entity
    assert_includes response.body, "Execution has started"
    post slice_document_path(@spec)
    assert_response :unprocessable_entity
  ensure
    ENV["REDWRIGHT_SPEC_HARNESS"] = previous
  end
end
