require "test_helper"
require_relative "../../support/protocol_reference_harness_fixture"

module ProjectProtocols
  class DocumentsTest < ActiveSupport::TestCase
    include ProtocolReferenceHarnessFixture

    setup do
      @project = create_project(key: "protocol-concerns")
      @store = write_protocol_files(project: @project, documents: [{path: "AGENTS.md", body: "# Operating Contract\n\nKeep existing rules.\n"}])
      @harness = ReferenceHarness.new(program: protocol_reference_harness(@store.root))
      @service = Documents.new(store: @store, harness: @harness)
    end

    test "one concern lifecycle maintains files and references" do
      # Exercise the actual subprocess boundary and keep the Markdown body byte-for-byte.
      original = @store.snapshot("AGENTS.md").fetch(:body)
      body = "# Invariants\n\n- Preserve explicit user scope.\n"
      document = @service.create(name: "collaboration rules.md", description: "Non-negotiable rules.", body: body)
      assert_equal ".agents/COLLABORATION_RULES.md", document.path
      assert_equal body, document.body
      assert_equal "Non-negotiable rules.", document.description
      assert @store.snapshot("AGENTS.md").fetch(:body).start_with?(original.rstrip)
      assert_equal "AGENTS.md", @store.documents.first.path
      root_revision = document.agents_revision

      body = "# Updated rules\n\nPreserve the user's decisions.\n"
      # Body-only changes must not invoke the harness or touch AGENTS.md.
      plain = Documents.new(store: @store, harness: ReferenceHarness.new(program: "/bin/false"))
      document = plain.update(document, body: body, revision: document.revision)
      assert_equal body, document.body
      assert_equal root_revision, document.agents_revision

      old_path = document.path
      document = @service.update(document, name: "invariants", description: "Scope and collaboration boundaries.",
        body: body, revision: document.revision, agents_revision: document.agents_revision)
      assert_equal ".agents/INVARIANTS.md", document.path
      refute @store.root.join(old_path).exist?
      assert_equal body, document.body
      assert_equal "Scope and collaboration boundaries.", document.description
      assert_no_match old_path, @store.snapshot("AGENTS.md").fetch(:body)

      document = @service.update(document, description: "Safety and scope rules.", revision: document.revision)
      assert_equal "Safety and scope rules.", document.description
      assert_equal 1, @store.snapshot("AGENTS.md").fetch(:body).scan("`.agents/INVARIANTS.md`").size
      @service.delete(document, revision: document.revision, agents_revision: document.agents_revision)
      refute @store.root.join(document.path).exist?
      assert_no_match document.path, @store.snapshot("AGENTS.md").fetch(:body)
      assert_equal ["AGENTS.md"], @store.documents.map(&:path)
    end

    test "generation failures leave both files unchanged" do
      document = @service.create(name: "invariants", description: "Rules.", body: "Original")
      root = @store.snapshot("AGENTS.md")
      failing = Documents.new(store: @store, harness: ReferenceHarness.new(program: "/bin/false"))
      ["create", "rename", "delete"].each do |operation|
        assert_raises(Specifications::Error, operation) do
          case operation
          when "create" then failing.create(name: "new", body: "New")
          when "rename" then failing.update(document, name: "renamed", body: "Unsaved", revision: document.revision)
          when "delete" then failing.delete(document, revision: document.revision)
          end
        end
        assert_equal root, @store.snapshot("AGENTS.md")
        assert_equal "Original", @store.snapshot(document.path).fetch(:body)
        refute @store.root.join(".agents/NEW.md").exist?
        refute @store.root.join(".agents/RENAMED.md").exist?
      end
    end

    test "external edits during generation cannot be overwritten" do
      # The double represents an external editor writing while the model is running.
      ["AGENTS.md", ".agents/INVARIANTS.md"].each do |changed_path|
        document = @store.documents.find { |entry| entry.path == ".agents/INVARIANTS.md" } ||
          @service.create(name: "invariants", description: "Rules.", body: "Original")
        root_before = @store.snapshot("AGENTS.md")
        root = @store.root
        harness = Object.new
        harness.define_singleton_method(:generate) do |**|
          root.join(changed_path).write("External edit")
          {"body" => "# Contract\n\n- `.agents/RENAMED.md` — Updated rules.\n"}
        end
        service = Documents.new(store: @store, harness: harness)
        error = assert_raises(Specifications::Error) do
          service.update(document, name: "renamed", description: "Updated rules.", revision: document.revision)
        end
        assert_equal :conflict, error.code
        assert_equal "External edit", root.join(changed_path).read
        refute root.join(".agents/RENAMED.md").exist?
        assert_equal root_before, @store.snapshot("AGENTS.md") unless changed_path == "AGENTS.md"
      end
    end

    test "invalid names collisions and entrypoint changes preserve files" do
      document = @service.create(name: "invariants", body: "Original")
      root = @store.snapshot("AGENTS.md")
      ["../outside", "nested/name", "", "bad.name"].each do |name|
        assert_raises(Specifications::Error, name) { @service.create(name: name, body: "Bad") }
      end
      assert_raises(Specifications::Error) { @service.create(name: "invariants", body: "Duplicate") }
      agents = @store.find_path("AGENTS.md")
      assert_raises(Specifications::Error) { @service.update(agents, name: "renamed", revision: agents.revision) }
      assert_raises(Specifications::Error) { @service.delete(agents, revision: agents.revision) }
      assert_equal root, @store.snapshot("AGENTS.md")
      assert_equal "Original", @store.snapshot(document.path).fetch(:body)
    end

    test "a failed entrypoint write rolls back the new concern" do
      # A read-only workspace permits the concern write in .agents but rejects AGENTS.
      original = @store.snapshot("AGENTS.md")
      FileUtils.mkdir_p(@store.root.join(".agents"))
      FileUtils.mkdir_p(@store.root.join(".rw"))
      mode = @store.root.stat.mode & 0o777
      @store.root.chmod(0o500)
      assert_raises(Specifications::Error) do
        @store.apply({".agents/NEW.md" => "New", "AGENTS.md" => "Updated"},
          expected: {".agents/NEW.md" => nil, "AGENTS.md" => original.fetch(:revision)})
      end
      assert_equal original, @store.snapshot("AGENTS.md")
      refute @store.root.join(".agents/NEW.md").exist?
    ensure
      @store.root.chmod(mode) if mode
    end
  end
end
