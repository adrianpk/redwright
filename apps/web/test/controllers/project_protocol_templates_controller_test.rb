require "test_helper"

class ProjectProtocolTemplatesControllerTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "template-admin@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  def create_non_admin_user!
    User.create!(
      email_address: "template-user@example.com",
      password: "password-123",
      password_confirmation: "password-123",
      roles_json: "[\"programmer\"]"
    )
  end

  test "index requires admin" do
    admin = create_admin_user!
    user = create_non_admin_user!
    sign_in_as(user)

    get protocol_templates_path

    assert_redirected_to root_path
    assert_equal admin.email_address, User.find_by(email_address: admin.email_address).email_address
  end

  test "index renders common and stack templates for admin" do
    admin = create_admin_user!
    sign_in_as(admin)

    get protocol_templates_path

    assert_response :success
    assert_match "Settings", response.body
    assert_match "Common Protocol Templates", response.body
    assert_match "Stack Protocol Templates", response.body
  end

  test "common template renders canonical cards and playbooks route" do
    admin = create_admin_user!
    sign_in_as(admin)

    get common_protocol_templates_path

    assert_response :success
    assert_match "Common Protocol Templates", response.body
    assert_match "Playbooks", response.body
    assert_match "Agent Operating Contract", response.body
  end

  test "stacks overview renders stack templates and create entry point" do
    admin = create_admin_user!
    sign_in_as(admin)

    get stacks_protocol_templates_path

    assert_response :success
    assert_match "Stack Protocol Templates", response.body
    assert_match "Rails Protocol Templates", response.body
    assert_match "New Stack Template", response.body
  end

  test "create stack template set and show per-stack management screen" do
    admin = create_admin_user!
    sign_in_as(admin)

    post stacks_protocol_templates_path, params: {
      project_protocol_template: {
        key: "zig-web",
        name: "Zig Web Protocol Template"
      }
    }

    template = ProjectProtocolTemplate.find_by!(template_kind: "stack", key: "zig-web")
    assert_redirected_to protocol_template_path(template)
    assert_equal ["zig-web"], template.matchers
    assert_equal ["architecture", "conventions"], template.documents.order(:position).pluck(:key)
    assert_equal "# Architecture\n\n", template.documents.find_by!(key: "architecture").body
  end

  test "show and update template document for admin" do
    admin = create_admin_user!
    sign_in_as(admin)
    template = ProjectProtocols::TemplateCatalog.new.all_templates.find { |entry| entry.key == "rails" && entry.template_kind == "stack" }
    document = template.documents.find_by!(key: "architecture")

    get protocol_template_path(template)
    assert_response :success
    assert_match "Rails Protocol Templates", response.body

    get edit_protocol_template_document_path(template, document)
    assert_response :success
    assert_match "Edit Template Document", response.body

    patch protocol_template_document_path(template, document), params: {
      project_protocol_template_document: {
        title: "Architecture Updated",
        body: "# Rails Architecture\n\nUpdated through admin."
      }
    }

    assert_redirected_to protocol_template_path(template)
    assert_equal "Architecture Updated", document.reload.title
    assert_match(/Updated through admin/, document.reload.body)
  end

  test "delete and recreate template entry without duplication" do
    admin = create_admin_user!
    sign_in_as(admin)
    template = ProjectProtocols::TemplateCatalog.new.all_templates.find { |entry| entry.key == "rails" && entry.template_kind == "stack" }
    document = template.documents.find_by!(key: "architecture")

    delete protocol_template_document_path(template, document)

    assert_redirected_to protocol_template_path(template)
    assert_nil template.reload.documents.find_by(id: document.id)

    post documents_protocol_template_path(template), params: {key: "architecture"}

    recreated = template.reload.documents.find_by!(key: "architecture")
    assert_redirected_to edit_protocol_template_document_path(template, recreated)

    assert_no_difference -> { template.reload.documents.where(key: "architecture").count } do
      post documents_protocol_template_path(template), params: {key: "architecture"}
    end
  end
end
