module ProjectProtocols
  class TemplateSetCatalog
    Entry = Struct.new(
      :key,
      :path,
      :title,
      :layer,
      :position,
      :body,
      :document,
      :missing,
      :playbooks_index,
      :playbook,
      keyword_init: true
    ) do
      def missing?
        missing == true
      end

      def playbooks_index?
        playbooks_index == true
      end

      def playbook?
        playbook == true
      end
    end

    def initialize(template:, registry: TemplateRegistry.new)
      @template = template
      @registry = registry
    end

    def top_level_entries
      entries.reject(&:playbook?)
    end

    def playbook_entries
      entries.select(&:playbook?)
    end

    def createable_entry!(key)
      entry = entries.find { |candidate| candidate.key == key.to_s }
      raise ActiveRecord::RecordNotFound, "Unknown template entry #{key}." unless entry

      entry
    end

    private

    attr_reader :template, :registry

    def entries
      @entries ||= begin
        persisted = template.documents.index_by(&:key)

        definitions = expected_definitions.index_by { |definition| definition.fetch("key") }
        persisted.each_value do |document|
          definitions[document.key] ||= document.attributes.slice("key", "path", "title", "layer", "position", "body")
        end

        definitions.values.map do |definition|
          document = persisted[definition.fetch("key")]

          Entry.new(
            key: definition.fetch("key"),
            path: definition.fetch("path"),
            title: definition.fetch("title"),
            layer: definition.fetch("layer"),
            position: definition.fetch("position", 999),
            body: document&.body || definition.fetch("body"),
            document: document,
            missing: document.nil?,
            playbooks_index: definition.fetch("key") == "playbooks_index",
            playbook: definition.fetch("path").start_with?(".agents/playbooks/")
          )
        end.sort_by { |entry| [entry.path == "AGENTS.md" ? 0 : 1, entry.title.downcase] }
      end
    end

    def expected_definitions
      if template.common?
        registry.common_documents
      else
        registry.stack_template_definition(template.key).fetch("documents")
      end
    end
  end
end
