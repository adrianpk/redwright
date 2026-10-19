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
      @store.create(".agents/UNLISTED.md", "# Unlisted concern")
      root = @store.snapshot("AGENTS.md")
      failing = Documents.new(store: @store, harness: ReferenceHarness.new(program: "/bin/false"))
      ["create", "rename", "delete", "sync"].each do |operation|
        assert_raises(Specifications::Error, operation) do
          case operation
          when "create" then failing.create(name: "new", body: "New")
          when "rename" then failing.update(document, name: "renamed", body: "Unsaved", revision: document.revision)
          when "delete" then failing.delete(document, revision: document.revision)
          when "sync"
            agents = @store.find_path("AGENTS.md")
            failing.sync_references(agents, revision: agents.revision)
          end
        end
        assert_equal root, @store.snapshot("AGENTS.md")
        assert_equal "Original", @store.snapshot(document.path).fetch(:body)
        refute @store.root.join(".agents/NEW.md").exist?
        refute @store.root.join(".agents/RENAMED.md").exist?
      end
    end

    test "playbook lifecycle maintains its own index" do
      # Exercise the same subprocess and filesystem boundary with the playbook owner.
      document = @service.create(collection: "playbooks", name: "delivery", description: "Delivery steps.", body: "# Delivery\n")
      assert_equal ".agents/playbooks/DELIVERY.md", document.path
      assert_equal "Delivery steps.", document.description
      agents = @store.snapshot("AGENTS.md")
      assert_includes agents.fetch(:body), "`.agents/PLAYBOOKS.md`"
      assert_no_match document.path, agents.fetch(:body)
      assert_includes @store.snapshot(".agents/PLAYBOOKS.md").fetch(:body), "`.agents/playbooks/DELIVERY.md` — Delivery steps."

      plain = Documents.new(store: @store, harness: ReferenceHarness.new(program: "/bin/false"))
      index = @store.snapshot(".agents/PLAYBOOKS.md")
      document = plain.update(document, body: "# Updated delivery\n", revision: document.revision)
      assert_equal index, @store.snapshot(".agents/PLAYBOOKS.md")
      document = @service.update(document, name: "release", description: "Release steps.", revision: document.revision,
        index_revision: document.index_revision, agents_revision: document.agents_revision)
      assert_equal ".agents/playbooks/RELEASE.md", document.path
      assert_equal "Release steps.", document.description
      assert_no_match ".agents/playbooks/DELIVERY.md", @store.snapshot(".agents/PLAYBOOKS.md").fetch(:body)
      assert_equal agents, @store.snapshot("AGENTS.md")
      @service.delete(document, revision: document.revision, index_revision: document.index_revision)
      refute @store.root.join(document.path).exist?
      assert_no_match document.path, @store.snapshot(".agents/PLAYBOOKS.md").fetch(:body)
      assert_equal agents, @store.snapshot("AGENTS.md")

      index = @store.find_path(".agents/PLAYBOOKS.md")
      assert_raises(Specifications::Error) { @service.update(index, name: "renamed", revision: index.revision) }
      assert_raises(Specifications::Error) { @service.delete(index, revision: index.revision) }
    end

    test "sync delegates playbooks while preserving other instructions" do
      # Reconcile the former flat list and keep nested procedures discoverable through their index.
      @store.create(".agents/PLAYBOOKS.md", "# Playbooks Index\n\nKeep these index instructions.\n\n")
      @store.create(".agents/playbooks/ONE.md", "# First procedure\n")
      @store.create(".agents/playbooks/team/TWO.md", "# Second procedure\n")
      original = "# Contract\n\nKeep this rule about `.agents/playbooks/ONE.md`.\n\n" \
        "- `.agents/PLAYBOOKS.md` — Project procedures.\n- `.agents/playbooks/ONE.md` — Old first description.\n" \
        "- `.agents/playbooks/team/TWO.md` — Old second description.\n\n"
      @store.root.join("AGENTS.md").write(original)
      agents = @store.find_path("AGENTS.md")
      result = @service.sync_references(agents, revision: agents.revision)
      assert_includes result.body, "Keep this rule about `.agents/playbooks/ONE.md`."
      assert_includes result.body, "`.agents/PLAYBOOKS.md` — Project procedures."
      assert_no_match(/^- `\.agents\/playbooks\//, result.body)
      index = @store.find_path(".agents/PLAYBOOKS.md")
      assert index.body.start_with?("# Playbooks Index\n\nKeep these index instructions.\n\n")
      assert_includes index.body, "`.agents/playbooks/ONE.md` — Old first description."
      assert_includes index.body, "`.agents/playbooks/team/TWO.md` — Old second description."

      @store.create(".agents/playbooks/THREE.md", "# Third procedure\n")
      agents_snapshot = @store.snapshot("AGENTS.md")
      pending = index.body + "\nKeep this pending index edit.\n"
      result = @service.sync_references(index, body: pending, revision: index.revision)
      assert result.body.start_with?(pending)
      assert_includes result.body, "`.agents/playbooks/THREE.md` — Third procedure"
      assert_equal agents_snapshot, @store.snapshot("AGENTS.md")
      plain = Documents.new(store: @store, harness: ReferenceHarness.new(program: "/bin/false"))
      assert_equal agents_snapshot.fetch(:body), plain.sync_references(@store.find_path("AGENTS.md"), revision: agents_snapshot.fetch(:revision)).body
    end

    test "playbook index conflicts preserve procedures" do
      # The editor revision must protect the actual owner rather than only AGENTS.
      document = @service.create(collection: "playbooks", name: "delivery", description: "Delivery steps.", body: "Original")
      agents = @store.snapshot("AGENTS.md")
      @store.root.join(".agents/PLAYBOOKS.md").write("External index edit")
      ["rename", "delete"].each do |operation|
        error = assert_raises(Specifications::Error, operation) do
          if operation == "rename"
            @service.update(document, name: "release", revision: document.revision, index_revision: document.index_revision)
          else
            @service.delete(document, revision: document.revision, index_revision: document.index_revision)
          end
        end
        assert_equal :conflict, error.code
        assert_equal "Original", @store.root.join(document.path).read
        assert_equal "External index edit", @store.root.join(".agents/PLAYBOOKS.md").read
        assert_equal agents, @store.snapshot("AGENTS.md")
      end
    end

    test "editing a playbook transfers the previous flat references" do
      # Metadata edits must not strand the other procedures when the old flat list is delegated.
      @store.create(".agents/PLAYBOOKS.md", "# Playbooks Index\n")
      @store.create(".agents/playbooks/ONE.md", "# First procedure\n")
      @store.create(".agents/playbooks/TWO.md", "# Second procedure\n")
      @store.root.join("AGENTS.md").write("# Contract\n\n- `.agents/playbooks/ONE.md` — First.\n- `.agents/playbooks/TWO.md` — Second.\n")
      document = @store.find_path(".agents/playbooks/ONE.md")

      result = @service.update(document, name: "renamed", description: "Updated first procedure.", revision: document.revision,
        index_revision: document.index_revision, agents_revision: document.agents_revision)

      index = @store.snapshot(".agents/PLAYBOOKS.md").fetch(:body)
      assert_includes index, "`.agents/playbooks/RENAMED.md` — Updated first procedure."
      assert_includes index, "`.agents/playbooks/TWO.md` — Second."
      assert_no_match ".agents/playbooks/ONE.md", index
      assert_equal "# First procedure\n", result.body
      assert_equal "# Second procedure\n", @store.root.join(".agents/playbooks/TWO.md").read
      assert_no_match ".agents/playbooks/", @store.snapshot("AGENTS.md").fetch(:body)
      assert_includes @store.snapshot("AGENTS.md").fetch(:body), "`.agents/PLAYBOOKS.md`"
    end

    test "multi index sync applies all changes together" do
      # A later generation failure or concurrent write must not commit the earlier staged index.
      @store.create(".agents/playbooks/NEW.md", "# New procedure\n")
      ["generation failure", "external index edit"].each do |scenario|
        agents = @store.find_path("AGENTS.md")
        original = @store.snapshot("AGENTS.md")
        root = @store.root
        harness = Object.new
        harness.define_singleton_method(:generate) do |context:, **|
          if context.fetch("index_path") == "AGENTS.md"
            raise Specifications::Error, "Generation failed" if scenario == "generation failure"
            root.join(".agents/PLAYBOOKS.md").write("External index edit")
          end
          body = context.fetch("index_body")
          context.fetch("documents").each { |entry| body += "\n- `#{entry.fetch(:path)}` — Procedure index.\n" }
          {"body" => body}
        end
        service = Documents.new(store: @store, harness: harness)
        assert_raises(Specifications::Error, scenario) { service.sync_references(agents, revision: agents.revision) }
        assert_equal original, @store.snapshot("AGENTS.md")
        assert_equal "# New procedure\n", @store.root.join(".agents/playbooks/NEW.md").read
        if scenario == "generation failure"
          refute @store.root.join(".agents/PLAYBOOKS.md").exist?
        else
          assert_equal "External index edit", @store.root.join(".agents/PLAYBOOKS.md").read
        end
      end
    end

    test "sync appends missing concerns and remains idempotent" do
      # Real files and a subprocess cover external additions, nested concerns, and pending edits.
      @store.create(".agents/KNOWN.md", "# Known rules")
      sources = {".agents/CUSTOM.md" => "# Custom collaboration rules\n", ".agents/nested/NOTES.md" => "# Nested notes\n"}
      sources.each { |path, body| @store.create(path, body) }
      @store.root.join("AGENTS.md").write("# Contract\n\nUse [known rules](.agents/KNOWN.md).\n\n")
      agents = @store.find_path("AGENTS.md")
      pending = agents.body + "Keep this pending edit.\n\n"

      result = @service.sync_references(agents, body: pending, revision: agents.revision)

      assert result.body.start_with?(pending)
      assert_equal 1, result.body.scan(".agents/KNOWN.md").size
      sources.each do |path, body|
        assert_equal body, @store.root.join(path).read
        assert_equal 1, result.body.scan("`#{path}`").size
      end
      assert_includes result.body, "`.agents/CUSTOM.md` — Custom collaboration rules"
      snapshot = @store.snapshot("AGENTS.md")
      no_harness = Documents.new(store: @store, harness: ReferenceHarness.new(program: "/bin/false"))
      repeated = no_harness.sync_references(result, revision: result.revision)
      assert_equal snapshot, @store.snapshot("AGENTS.md")
      assert_equal result.body, repeated.body
    end

    test "sync rejects rewrites missing references and duplicates" do
      # Invalid model responses must never replace the user's entrypoint.
      @store.create(".agents/NEW.md", "# New concern")
      agents = @store.find_path("AGENTS.md")
      original = @store.snapshot("AGENTS.md")
      reference = "\n- `.agents/NEW.md` — New concern.\n"
      {"rewrite" => reference, "missing" => agents.body, "duplicate" => agents.body + reference * 2}.each do |name, output|
        harness = Object.new
        harness.define_singleton_method(:generate) { |**| {"body" => output} }
        service = Documents.new(store: @store, harness: harness)
        assert_raises(Specifications::Error, name) { service.sync_references(agents, revision: agents.revision) }
        assert_equal original, @store.snapshot("AGENTS.md"), name
      end
    end

    test "sync protects external changes during generation" do
      # Either a changed entrypoint or changed source invalidates the generated references.
      @store.create(".agents/NEW.md", "# New concern")
      ["AGENTS.md", ".agents/NEW.md"].each do |changed_path|
        agents = @store.find_path("AGENTS.md")
        original = @store.snapshot("AGENTS.md")
        root = @store.root
        harness = Object.new
        harness.define_singleton_method(:generate) do |context:, **|
          root.join(changed_path).write("External edit")
          {"body" => context.fetch("index_body") + "\n- `.agents/NEW.md` — New concern.\n"}
        end
        service = Documents.new(store: @store, harness: harness)

        error = assert_raises(Specifications::Error) { service.sync_references(agents, revision: agents.revision) }

        assert_equal :conflict, error.code
        assert_equal "External edit", root.join(changed_path).read
        assert_equal original, @store.snapshot("AGENTS.md") unless changed_path == "AGENTS.md"
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
      assert_raises(Specifications::Error) { @service.create(collection: "../outside", name: "new", body: "Bad") }
      assert_raises(Specifications::Error) { @service.create(name: "invariants", body: "Duplicate") }
      agents = @store.find_path("AGENTS.md")
      assert_raises(Specifications::Error) { @service.update(agents, name: "renamed", revision: agents.revision) }
      assert_raises(Specifications::Error) { @service.delete(agents, revision: agents.revision) }
      assert_raises(Specifications::Error) { @service.sync_references(document, revision: document.revision) }
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
