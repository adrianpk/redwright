require "test_helper"

module ProjectProtocols
  class InitializationServiceTest < ActiveSupport::TestCase
    setup do
      @project = create_project(key: "initialize-files")
      write_protocol_files(project: @project)
    end

    # New projects receive the current document set and matching stack files.
    test "initializes files from current templates" do
      result = InitializationService.new(project: @project).call
      assert result.fetch("initialized")
      paths = @project.protocol_files.documents.map(&:path)
      %w[AGENTS.md .agents/COMMUNICATION.md .agents/LANGUAGE.md .agents/REPORTING.md .agents/TICKETS.md .agents/playbooks/quiz.md .agents/protocol/ACTIVITY.md .agents/stacks/ruby/CONVENTIONS.md].each do |path|
        assert_includes paths, path
      end
      assert_equal "active", @project.protocol_state.fetch("status")
    end

    # An existing custom set must survive initialization, including missing defaults.
    test "preserves the existing project set" do
      @project.protocol_files.create(".agents/CUSTOM.md", "custom")
      result = InitializationService.new(project: @project).call
      refute result.fetch("initialized")
      assert_equal [".agents/CUSTOM.md"], @project.protocol_files.documents.map(&:path)
    end

    # Removing every protocol from an initialized workspace is a valid empty set.
    test "preserves an initialized empty set" do
      manifest = @project.protocol_files.root.join(".redwright", "manifest.yml")
      FileUtils.mkdir_p(manifest.dirname)
      manifest.write("schema_version: 1\n")
      result = InitializationService.new(project: @project).call
      refute result.fetch("initialized")
      assert_empty @project.protocol_files.documents
    end
  end
end
