module ProjectProtocols
  class IndexCatalog
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

      def existing?
        !missing?
      end
    end

    def initialize(project:, registry: TemplateRegistry.new)
      @project = project
      @registry = registry
    end

    def top_level_entries
      entries.reject(&:playbook?)
    end

    def playbook_entries
      entries.select(&:playbook?)
    end

    def find_expected_entry!(key)
      entry = entries.find { |candidate| candidate.key == key.to_s }
      raise ActiveRecord::RecordNotFound, "Unknown protocol entry #{key}." unless entry

      entry
    end

    private

    attr_reader :project, :registry

    def entries
      @entries ||= begin
        persisted = project.protocol&.documents&.index_by(&:key) || {}

        Composer.new(project: project, registry: registry).call.documents.map do |definition|
          document = persisted[definition.fetch("key")]

          Entry.new(
            key: definition.fetch("key"),
            path: definition.fetch("path"),
            title: definition.fetch("title"),
            layer: definition.fetch("layer"),
            position: definition.fetch("position"),
            body: document&.body || definition.fetch("body"),
            document: document,
            missing: document.nil?,
            playbooks_index: definition.fetch("key") == "playbooks_index",
            playbook: definition.fetch("path").start_with?(".agents/playbooks/")
          )
        end
      end
    end
  end
end
