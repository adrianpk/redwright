require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new is available when no users exist" do
    get new_user_path

    assert_response :success
    assert_match("Create admin account", response.body)
  end

  test "create bootstraps first admin and redirects to root" do
    post users_path, params: {
      user: {
        email_address: "owner@example.com",
        password: "password-123",
        password_confirmation: "password-123"
      }
    }

    assert_redirected_to root_path
    user = User.find_by(email_address: "owner@example.com")
    refute_nil(user)
    assert_equal([ "admin" ], user.roles)
  end

  test "create is blocked once instance has users" do
    User.create!(
      email_address: "owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )

    post users_path, params: {
      user: {
        email_address: "other@example.com",
        password: "password-123",
        password_confirmation: "password-123"
      }
    }

    assert_redirected_to new_session_path
    assert_nil(User.find_by(email_address: "other@example.com"))
    follow_redirect!
    assert_select "#application-flash[data-kind='alert'][role='alert']:not([hidden]) [data-flash-message]", text: "Registration is closed for this instance."
    assert_select "[role='alert']", count: 1
  end
end

