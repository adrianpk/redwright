ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require_relative "support/agent_ticket_execution_workspace_fixture"
require "rails/test_help"
require "securerandom"
require "tmpdir"
require "fileutils"

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

  def create_use_case(project: nil, name: "Billing", description: nil, **attrs)
    use_case_project = project || create_project(name: "Use Case Project", key: "use-case-#{SecureRandom.hex(4)}")
    UseCase.create!(
      {
        project: use_case_project,
        name: name,
        description: description || "#{name} description"
      }.merge(attrs)
    )
  end

  def write_protocol_files(project:, documents: [])
    unless File.directory?(project.root_path)
      path = Dir.mktmpdir("redwright-protocol-test-")
      (@protocol_test_directories ||= []) << path
      project.update!(root_path: path)
    end
    documents.each_with_index do |attributes, index|
      path = Pathname.new(project.root_path).join(attributes.fetch(:path, ".agents/doc-#{index}.md"))
      FileUtils.mkdir_p(path.dirname)
      path.write(attributes.fetch(:body, "Protocol body #{index}"))
    end
    project.protocol_files
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
  include AgentTicketExecutionWorkspaceFixture
end

class ActiveSupport::TestCase
  teardown do
    Array(@protocol_test_directories).each { |path| FileUtils.remove_entry(path) if File.directory?(path) }
  end
end
