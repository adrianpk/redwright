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

  def create_document(project: nil, **attrs)
    document_project = project || create_project(name: "Docs Project", key: "docs-#{SecureRandom.hex(4)}")
    defaults = {
      artifact_type: "draft",
      title: "Draft #{SecureRandom.hex(3)}",
      body: "Draft body",
      editable: true,
      project: document_project
    }
    Document.create!(defaults.merge(attrs))
  end

  def create_project_protocol(project:, status: "draft", documents: [])
    protocol = ProjectProtocol.create!(project: project, status: status)
    documents.each_with_index do |attrs, index|
      protocol.documents.create!(
        {
          key: "doc-#{index}",
          path: ".agents/doc-#{index}.md",
          title: "Protocol Doc #{index}",
          layer: "behavioral",
          position: index,
          body: "Protocol body #{index}",
          provenance: {}
        }.merge(attrs)
      )
    end
    protocol
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
