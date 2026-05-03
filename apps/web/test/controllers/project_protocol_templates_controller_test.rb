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
    assert_match "Protocol Templates", response.body
    assert_match "Common Templates", response.body
    assert_match "Stack Templates", response.body
    assert_match "Common Protocol Template", response.body
    assert_match "Rails Protocol Template", response.body
  end

  test "show and update template document for admin" do
    admin = create_admin_user!
    sign_in_as(admin)
    template = ProjectProtocols::TemplateCatalog.new.all_templates.find { |entry| entry.key == "rails" && entry.template_kind == "stack" }
    document = template.documents.find_by!(key: "architecture")

    get protocol_template_path(template)
    assert_response :success
    assert_match "Rails Protocol Template", response.body

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
end
