ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "securerandom"

class ActiveSupport::TestCase
end

module ProjectBoardTestHelper
  def create_project(name: "Factory Project", key: "factory")
    Project.create!(
      name: name,
      description: "#{name} description",
      root_path: "/workspace/projects/#{key}",
      repo_url: "https://codeberg.org/acme/#{key}",
      stack_slug: "ruby"
    )
  end

  def create_board(name: "Factory", project_key: "factory", project: nil)
    Board.create!(name: name, project_key: project_key, project: (project || create_project(key: project_key)))
  end

  def create_document_artifact(project: nil, **attrs)
    artifact_project = project || create_project(name: "Docs Project", key: "docs-#{SecureRandom.hex(4)}")
    defaults = {
      artifact_type: "draft",
      title: "Draft #{SecureRandom.hex(3)}",
      body: "Draft body",
      editable: true,
      project: artifact_project
    }
    DocumentArtifact.create!(defaults.merge(attrs))
  end
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
  include ProjectBoardTestHelper
end

class ActiveSupport::TestCase
  include ProjectBoardTestHelper
end
