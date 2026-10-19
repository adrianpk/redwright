require "test_helper"

module ProjectProtocols
  class InitializationServiceTest < ActiveSupport::TestCase
    setup do
      @project = create_project(key: "initialize-files")
      write_protocol_files(project: @project)
    end

    # Setup copies template defaults once into a new project's own workspace.
    test "initializes files from templates" do
      result = InitializationService.new(project: @project).call
      assert result.fetch("initialized")
      paths = @project.protocol_files.documents.map(&:path)
      %w[AGENTS.md .agents/CONVENTIONS.md .agents/ARCHITECTURE.md .agents/playbooks/questionnaires.md].each do |path|
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

    test "materializes Odin and Racket baselines into project files" do
      # Cover real template selection and file creation, rather than only catalog visibility.
      {"odin" => "Odin", "racket" => "Racket"}.each do |stack, title|
        project = create_project(key: "initialize-#{stack}")
        project.update!(stack_slug: stack)
        write_protocol_files(project: project)

        result = InitializationService.new(project: project).call

        assert result.fetch("initialized"), stack
        assert_equal [stack], result.fetch("stack_keys"), stack
        refute result.fetch("fallback_used"), stack
        assert project.protocol_files.find_path("AGENTS.md").body.present?, stack
        %w[ARCHITECTURE CONVENTIONS DOCUMENTING LINTING].each do |concern|
          document = project.protocol_files.find_path(".agents/#{concern}.md")
          assert document.body.start_with?("# #{title} "), "#{stack}: #{concern}"
        end
        architecture = project.protocol_files.find_path(".agents/ARCHITECTURE.md")
        architecture.update(body: "# Project customization", revision: architecture.revision)
        repeated = InitializationService.new(project: project).call
        refute repeated.fetch("initialized"), stack
        assert_equal "# Project customization", project.protocol_files.find_path(".agents/ARCHITECTURE.md").body, stack
      end
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
