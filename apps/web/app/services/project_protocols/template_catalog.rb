module ProjectProtocols
  class TemplateCatalog
    def initialize(registry: TemplateRegistry.new)
      @registry = registry
    end

    def common_documents
      ensure_seeded!
      common_template.documents.map { |document| template_document_state(document) }
    end

    def stack_templates
      ensure_seeded!
      ProjectProtocolTemplate.where(template_kind: "stack", status: "active").order(:key).each_with_object({}) do |template, hash|
        hash[template.key] = {
          "stack_key" => template.key,
          "matchers" => template.matchers,
          "documents" => template.documents.map { |document| template_document_state(document) }
        }
      end
    end

    def available_stack_keys
      stack_templates.keys
    end

    def all_templates
      ensure_seeded!
      ProjectProtocolTemplate.includes(:documents).order(:template_kind, :key)
    end

    def find_template(id)
      ensure_seeded!
      ProjectProtocolTemplate.includes(:documents).find(id)
    end

    private

    attr_reader :registry

    def ensure_seeded!
      seed_common_template!
      seed_stack_templates!
    end

    def common_template
      ProjectProtocolTemplate.find_by!(template_kind: "common", key: "common")
    end

    def seed_common_template!
      template = ProjectProtocolTemplate.find_or_initialize_by(template_kind: "common", key: "common")
      if template.new_record?
        template.name = "Common Protocol Template"
        template.matchers = []
        template.status = "active"
        template.save!
        sync_documents!(template, registry.common_documents)
      end
      template
    end

    def seed_stack_templates!
      registry.stack_templates.each_value do |definition|
        template = ProjectProtocolTemplate.find_or_initialize_by(template_kind: "stack", key: definition.fetch("stack_key"))
        if template.new_record?
          template.name = "#{definition.fetch('stack_key').capitalize} Protocol Template"
          template.matchers = definition.fetch("matchers")
          template.status = "active"
          template.save!
          sync_documents!(template, definition.fetch("documents"))
        end
      end
    end

    def sync_documents!(template, documents)
      documents.each_with_index do |document, index|
        template.documents.create!(
          key: document.fetch("key"),
          path: document.fetch("path"),
          title: document.fetch("title"),
          layer: document.fetch("layer"),
          position: document.fetch("position", index),
          body: document.fetch("body")
        )
      end
    end

    def template_document_state(document)
      {
        "key" => document.key,
        "path" => document.path,
        "title" => document.title,
        "layer" => document.layer,
        "position" => document.position,
        "body" => document.body
      }
    end
  end
end
