require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "first user is bootstrapped as admin" do
    user = User.create!(
      email_address: "owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )

    assert_equal([ "admin" ], user.roles)
    assert(user.admin?)
  end

  test "second user cannot become admin" do
    User.create!(
      email_address: "owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
    second = User.new(
      email_address: "agent@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
    second.roles = [ "admin" ]

    assert_not(second.valid?)
    assert_includes(second.errors.full_messages.join(" "), "admin is already assigned")
  end

  test "admin role cannot be combined with agent roles" do
    User.create!(
      email_address: "owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
    user = User.new(
      email_address: "bad@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
    user.roles = [ "admin", "programmer" ]

    assert_not(user.valid?)
    assert_includes(user.errors.full_messages.join(" "), "admin cannot be combined")
  end

  test "rejects unsupported roles" do
    User.create!(
      email_address: "owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
    user = User.new(
      email_address: "bad@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
    user.roles = [ "godmode" ]

    assert_not(user.valid?)
    assert_includes(user.errors.full_messages.join(" "), "unsupported roles")
  end
end

