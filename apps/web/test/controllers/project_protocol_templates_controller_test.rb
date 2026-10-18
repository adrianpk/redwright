require "test_helper"

class ProjectProtocolTemplatesControllerTest < ActionDispatch::IntegrationTest
  def with_catalog
    previous = Rails.configuration.x.protocols.template_root
    Rails.configuration.x.protocols.template_root = @template_root
    yield
  ensure
    Rails.configuration.x.protocols.template_root = previous
  end
  setup do
    @admin = User.create!(email_address: "template-admin@example.com", password: "password-123", password_confirmation: "password-123")
    @template_root = Dir.mktmpdir("protocol-template-web-")
    (@protocol_test_directories ||= []) << @template_root
    FileUtils.mkdir_p(File.join(@template_root, ".agents/stacks/ruby"))
    File.write(File.join(@template_root, "AGENTS.md"), "# Root template")
    File.write(File.join(@template_root, ".agents/stacks/ruby/CONVENTIONS.md"), "# Ruby conventions")
    @catalog = ProjectProtocols::TemplateCatalog.new(root: @template_root)
  end

  test "requires authentication" do
    get protocol_templates_path
    assert_redirected_to new_session_path
  end

  test "requires an administrator" do
    programmer = User.create!(email_address: "template-programmer@example.com", password: "password-123", password_confirmation: "password-123", roles: ["programmer"])
    sign_in_as(programmer)
    get protocol_templates_path
    assert_redirected_to root_path
  end

  # Template administration edits the backing Markdown files directly.
  test "edits a stack template file" do
    sign_in_as(@admin)
    template = @catalog.find_template("ruby")
    document = template.documents.first
    with_catalog do
      get edit_protocol_template_document_path(template, document)
      assert_response :success
      patch protocol_template_document_path(template, document), params: {
        protocol_document: {body: "# Updated Ruby conventions", revision: document.revision}
      }
      assert_redirected_to protocol_template_path(template)
    end
    assert_equal "# Updated Ruby conventions", File.read(File.join(@template_root, document.path))
  end

  test "lists file backed common and stack templates" do
    sign_in_as(@admin)
    with_catalog do
      get common_protocol_templates_path
      assert_response :success
      assert_match "Root template", response.body
      get stacks_protocol_templates_path
      assert_response :success
      assert_match "Ruby Protocol Templates", response.body
    end
  end

  test "creates a stack directory and Markdown file" do
    sign_in_as(@admin)
    with_catalog do
      post stacks_protocol_templates_path, params: {protocol_template: {key: "custom"}}
      template = @catalog.find_template("custom")
      assert_redirected_to protocol_template_path(template)
      post documents_protocol_template_path(template), params: {path: ".agents/stacks/custom/EXTRA.md"}
      assert_redirected_to edit_protocol_template_document_path(template, template.documents.first)
      assert File.file?(File.join(@template_root, ".agents/stacks/custom/EXTRA.md"))
    end
  end

  test "does not recreate deleted template files" do
    sign_in_as(@admin)
    template = @catalog.find_template("ruby")
    document = template.documents.first
    with_catalog do
      delete protocol_template_document_path(template, document)
      assert_redirected_to protocol_template_path(template)
      get protocol_template_path(template)
      assert_response :success
    end
    assert_empty template.documents
    refute File.exist?(File.join(@template_root, document.path))
  end
end
