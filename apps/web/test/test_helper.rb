ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
end

module AuthenticationTestHelper
  def sign_in_as(user, password: "password-123")
    post session_path, params: {
      email_address: user.email_address,
      password: password
    }
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationTestHelper
end
