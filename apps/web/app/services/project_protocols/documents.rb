module ProjectProtocols
  class Documents
    PLAYBOOKS_PATH = ".agents/PLAYBOOKS.md"

    def initialize(store:, harness: ReferenceHarness.new, authoring: Harnesses::Authoring)
      @store, @harness = store, harness
      @authoring = authoring
    end

    def create(**attributes)
      with_authoring("create") { |service| service.perform_create(**attributes) }
    end

    def update(document, **attributes)
      with_authoring("update", document) { |service| service.perform_update(document, **attributes) }
    end

    def delete(document, **attributes)
      with_authoring("delete", document) { |service| service.perform_delete(document, **attributes) }
    end

    def sync_references(document, **attributes)
      with_authoring("sync", document) { |service| service.perform_sync_references(document, **attributes) }
    end

    def perform_create(name: "", body: "", description: "", agents_revision: nil, index_revision: nil, collection: "protocols")
      unless ["protocols", "playbooks"].include?(collection)
        raise Specifications::Error, "Invalid protocol collection."
      end
      directory = collection == "playbooks" ? ".agents/playbooks" : ".agents"
      path = "#{directory}/#{filename(name)}"
      ensure_available!(path)
      index_path = reference_index(path)
      index = checked_index(index_path, index_path == "AGENTS.md" ? agents_revision : index_revision)
      updated = references("create", index, index_path: index_path, path: path, description: normalize_description(description))
      changes = {path => body.to_s, index_path => updated}
      expected = {path => nil, index_path => index&.fetch(:revision)}
      connect_playbooks(changes, expected, agents_revision) if index_path == PLAYBOOKS_PATH
      apply_changes(changes, expected: expected)
      @store.find_path(path)
    end

    def perform_update(document, body: document.body, revision: nil, name: document.name, description: document.description,
      agents_revision: nil, index_revision: nil)
      current = checked_document(document, revision)
      if document.reference_index?
        raise Specifications::Error, "Protocol indexes cannot be renamed." unless name == document.name
        apply_changes({document.path => body.to_s}, expected: {document.path => current.fetch(:revision)})
        return document.reload
      end
      path = name == document.name ? document.path : File.join(File.dirname(document.path), filename(name))
      description = normalize_description(description)
      if path == document.path && description == document.description
        apply_changes({path => body.to_s}, expected: {path => current.fetch(:revision)})
        return document.reload
      end
      ensure_available!(path) unless path == document.path
      index_path = document.reference_index_path
      index = checked_index(index_path, index_path == "AGENTS.md" ? agents_revision : index_revision)
      updated = references("update", index, index_path: index_path, old_path: document.path, path: path, description: description)
      changes = {path => body.to_s, index_path => updated}
      expected = {document.path => current.fetch(:revision), index_path => index&.fetch(:revision)}
      if path != document.path
        changes[document.path] = nil
        expected[path] = nil
      end
      connect_playbooks(changes, expected, agents_revision) if index_path == PLAYBOOKS_PATH
      apply_changes(changes, expected: expected)
      @store.find_path(path)
    end

    def perform_delete(document, revision: nil, agents_revision: nil, index_revision: nil)
      raise Specifications::Error, "Protocol indexes cannot be deleted." if document.reference_index?
      current = checked_document(document, revision)
      index_path = document.reference_index_path
      index = checked_index(index_path, index_path == "AGENTS.md" ? agents_revision : index_revision)
      updated = references("delete", index, index_path: index_path, old_path: document.path)
      changes = {index_path => updated, document.path => nil}
      expected = {document.path => current.fetch(:revision), index_path => index&.fetch(:revision)}
      connect_playbooks(changes, expected, agents_revision) if index_path == PLAYBOOKS_PATH
      apply_changes(changes, expected: expected)
    end

    def perform_sync_references(document, body: document.body, revision: nil)
      raise Specifications::Error, "References can only be synced from a protocol index." unless document.reference_index?
      current = checked_document(document, revision)
      sources = @store.documents.to_h do |entry|
        source = @store.snapshot(entry.path)
        raise Specifications::Error.new("Protocol files changed. Try syncing again.", code: :conflict) unless source
        [entry.path, source]
      end
      playbooks = sources.select { |path, _| path.start_with?(".agents/playbooks/") }
      agents_body = document.root? ? body.to_s : sources["AGENTS.md"]&.fetch(:body).to_s
      preserve_descriptions(playbooks, agents_body)
      changes, expected = {}, {document.path => current.fetch(:revision)}
      if document.root?
        if sources.key?(PLAYBOOKS_PATH) || playbooks.any?
          stage_sync(PLAYBOOKS_PATH, playbooks, changes, expected)
          sources[PLAYBOOKS_PATH] = {body: changes[PLAYBOOKS_PATH] || sources.fetch(PLAYBOOKS_PATH).fetch(:body),
            revision: sources[PLAYBOOKS_PATH]&.fetch(:revision)}
        end
        concerns = sources.reject { |path, _| path == "AGENTS.md" || path.start_with?(".agents/playbooks/") }
        stage_sync("AGENTS.md", concerns, changes, expected, body: body.to_s)
      else
        stage_sync(PLAYBOOKS_PATH, playbooks, changes, expected, body: body.to_s)
        connect_playbooks(changes, expected)
      end
      apply_changes(changes, expected: expected) if changes.any?
      document.reload
    end

    private

    def with_authoring(action, document = nil)
      return yield self unless @store.project
      authoring = @authoring.new(project: @store.project, purpose: "references", schema: ReferenceHarness::SCHEMA,
        harness: @harness, workspace_revision: {"action" => action, "document_ref" => document&.path})
      authoring.run do |harness|
        service = dup
        service.instance_variable_set(:@harness, harness)
        yield service
      end
    end

    def apply_changes(changes, expected:)
      @harness.check_deadline! if @harness.respond_to?(:check_deadline!)
      @store.apply(changes, expected: expected)
    end

    def reference_index(path)
      path.start_with?(".agents/playbooks/") ? PLAYBOOKS_PATH : "AGENTS.md"
    end

    def default_index(path)
      path == PLAYBOOKS_PATH ? "# Playbooks Index\n\nThis file indexes the project playbooks.\n" : "# Agent Operating Contract\n"
    end

    def checked_index(path, revision = nil)
      current = @store.snapshot(path)
      if !revision.nil? && revision.to_s != current&.fetch(:revision).to_s
        raise Specifications::Error.new("The reference index changed outside this editor. Reload it before saving.", code: :conflict)
      end
      current
    end

    def stage_sync(path, sources, changes, expected, body: nil)
      current = @store.snapshot(path)
      updated = synced_body(path, body || current&.fetch(:body) || default_index(path), sources)
      return if updated == current&.fetch(:body)
      changes[path] = updated
      expected[path] = current&.fetch(:revision) unless expected.key?(path)
      sources.each { |source_path, source| expected[source_path] = source.fetch(:revision) unless expected.key?(source_path) }
    end

    def connect_playbooks(changes, expected, agents_revision = nil)
      agents = checked_index("AGENTS.md", agents_revision)
      index = @store.snapshot(PLAYBOOKS_PATH)
      if delegated_paths(agents&.fetch(:body).to_s).any?
        sources = @store.playbook_entries.to_h do |entry|
          source = @store.snapshot(entry.path)
          raise Specifications::Error.new("Playbooks changed. Reload before saving.", code: :conflict) unless source
          [entry.path, source]
        end
        changes.each do |path, body|
          next unless path.start_with?(".agents/playbooks/")
          if body.nil?
            sources.delete(path)
          else
            sources[path] = {body: body, revision: expected.fetch(path)}
          end
        end
        preserve_descriptions(sources, agents.fetch(:body))
        stage_sync(PLAYBOOKS_PATH, sources, changes, expected, body: changes[PLAYBOOKS_PATH] || index&.fetch(:body))
      end
      source = {PLAYBOOKS_PATH => {body: changes[PLAYBOOKS_PATH] || index.fetch(:body), revision: index&.fetch(:revision)}}
      stage_sync("AGENTS.md", source, changes, expected)
    end

    def synced_body(path, body, sources)
      missing = sources.reject { |source_path, _| body.include?(source_path) }
      removed = path == "AGENTS.md" ? delegated_paths(body) : []
      return body if missing.empty? && removed.empty?
      documents = missing.map { |source_path, source| source.slice(:body, :description).merge(path: source_path) }
      updated = references("sync", {body: body}, index_path: path, documents: documents, removed_paths: removed)
      preserved = body.lines.reject { |line| removed.include?(listed_path(line)) }.join
      unless updated.start_with?(preserved)
        raise Specifications::Error, "Reference sync must preserve unrelated index content."
      end
      appended = updated.delete_prefix(preserved).lines.filter_map { |line| listed_path(line) }
      unless appended.sort == missing.keys.sort
        raise Specifications::Error, "The harness must append exactly one reference to each missing document."
      end
      updated
    end

    def listed_path(line)
      line[/\A\s*[-*+]\s+`(\.agents\/[^`\r\n]+\.md)`(?:\s|$)/, 1]
    end

    def delegated_paths(body)
      body.lines.filter_map { |line| listed_path(line) }.select { |path| path.start_with?(".agents/playbooks/") }
    end

    def preserve_descriptions(sources, body)
      body.lines.each do |line|
        path = listed_path(line)
        next unless sources.key?(path)
        sources.fetch(path)[:description] = line.split(/\s+—\s+/, 2)[1].to_s.strip
      end
    end

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

    def references(operation, index, index_path:, **change)
      context = {"operation" => operation, "index_path" => index_path,
        "index_body" => index&.fetch(:body) || default_index(index_path)}.merge(change.stringify_keys)
      body = @harness.generate(context: context, workspace: @store.root.to_s).fetch("body")
      path, old_path = change.values_at(:path, :old_path)
      if path && body.lines.count { |line| listed_path(line) == path } != 1
        raise Specifications::Error, "The harness must include exactly one reference to the document."
      end
      if old_path && old_path != path && body.include?(old_path)
        raise Specifications::Error, "The harness left an outdated document reference."
      end
      body
    end
  end
end
