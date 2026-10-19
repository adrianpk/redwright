module ProjectProtocols
  class Documents
    def initialize(store:, harness: ReferenceHarness.new)
      @store, @harness = store, harness
    end

    def create(name: "", body: "", description: "", agents_revision: nil)
      path = ".agents/#{filename(name)}"
      ensure_available!(path)
      agents = entrypoint(agents_revision)
      description = normalize_description(description)
      updated = references("create", agents, path: path, description: description)
      @store.apply({path => body.to_s, "AGENTS.md" => updated},
        expected: {path => nil, "AGENTS.md" => agents&.fetch(:revision)})
      @store.find_path(path)
    end

    def update(document, body: document.body, revision: nil, name: document.name, description: document.description, agents_revision: nil)
      current = checked_document(document, revision)
      if document.root?
        raise Specifications::Error, "AGENTS cannot be renamed." unless name == document.name
        @store.apply({document.path => body.to_s}, expected: {document.path => current.fetch(:revision)})
        return document.reload
      end
      path = name == document.name ? document.path : File.join(File.dirname(document.path), filename(name))
      description = normalize_description(description)
      if path == document.path && description == document.description
        @store.apply({path => body.to_s}, expected: {path => current.fetch(:revision)})
        return document.reload
      end
      ensure_available!(path) unless path == document.path
      agents = entrypoint(agents_revision)
      updated = references("update", agents, old_path: document.path, path: path, description: description)
      changes = {path => body.to_s, "AGENTS.md" => updated}
      expected = {document.path => current.fetch(:revision), "AGENTS.md" => agents&.fetch(:revision)}
      if path != document.path
        changes[document.path] = nil
        expected[path] = nil
      end
      @store.apply(changes, expected: expected)
      @store.find_path(path)
    end

    def delete(document, revision: nil, agents_revision: nil)
      raise Specifications::Error, "AGENTS is the protocol entrypoint and cannot be deleted." if document.root?
      current = checked_document(document, revision)
      agents = entrypoint(agents_revision)
      updated = references("delete", agents, old_path: document.path)
      @store.apply({"AGENTS.md" => updated, document.path => nil},
        expected: {document.path => current.fetch(:revision), "AGENTS.md" => agents&.fetch(:revision)})
    end

    private

    def filename(name)
      value = name.to_s.strip.sub(/\.md\z/i, "").upcase.gsub(/\s+/, "_")
      unless value.bytesize.between?(1, 80) && value.match?(/\A[A-Z][A-Z0-9_-]*\z/)
        raise Specifications::Error, "Name must start with a letter and contain only letters, numbers, spaces, underscores, or hyphens."
      end
      "#{value}.md"
    end

    def normalize_description(description)
      value = description.to_s.strip
      if value.length > 500 || value.match?(/[\r\n\x00]/)
        raise Specifications::Error, "Description must be one line of at most 500 characters."
      end
      value
    end

    def ensure_available!(path)
      target = @store.root.join(path)
      raise Specifications::Error, "A document with this name already exists." if target.exist? || target.symlink?
    end

    def checked_document(document, revision)
      current = @store.snapshot(document.path)
      unless current && current[:revision] == revision
        raise Specifications::Error.new("This file changed outside this editor. Reload it before saving.", code: :conflict)
      end
      current
    end

    def entrypoint(revision)
      current = @store.snapshot("AGENTS.md")
      if !revision.nil? && revision.to_s != current&.fetch(:revision).to_s
        raise Specifications::Error.new("AGENTS changed outside this editor. Reload it before saving.", code: :conflict)
      end
      current
    end

    def references(operation, agents, **change)
      context = {"operation" => operation, "agents_body" => agents&.fetch(:body) || "# Agent Operating Contract\n"}.merge(change.stringify_keys)
      body = @harness.generate(context: context, workspace: @store.root.to_s).fetch("body")
      path, old_path = change.values_at(:path, :old_path)
      if path && body.lines.count { |line| line.match?(/\A\s*[-*+]\s+`#{Regexp.escape(path)}`(?:\s|$)/) } != 1
        raise Specifications::Error, "The harness must include exactly one reference to the document."
      end
      if old_path && old_path != path && body.include?(old_path)
        raise Specifications::Error, "The harness left an outdated document reference."
      end
      body
    end
  end
end
