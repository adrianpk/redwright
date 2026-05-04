module ProjectProtocols
  class TemplateCatalog
    def initialize(registry: TemplateRegistry.new)
      @registry = registry
    end

    def common_documents
      ensure_seeded!
      common_template.documents.map { |document| template_document_state(document) }
    end

    def common_template
      ensure_seeded!
      ProjectProtocolTemplate.find_by!(template_kind: "common", key: "common")
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

    def stack_template_sets
      ensure_seeded!
      ProjectProtocolTemplate.includes(:documents).where(template_kind: "stack", status: "active").order(:key)
    end

    def find_template(id)
      ensure_seeded!
      ProjectProtocolTemplate.includes(:documents).find(id)
    end

    def create_stack_template!(stack_key:, name: nil)
      ensure_seeded!
      normalized_key = stack_key.to_s.strip.downcase.gsub(/\s+/, "-")
      raise ActiveRecord::RecordInvalid, ProjectProtocolTemplate.new if normalized_key.blank?

      template = ProjectProtocolTemplate.create!(
        template_kind: "stack",
        key: normalized_key,
        name: name.presence || "#{normalized_key.tr("-_", " ").split.map(&:capitalize).join(" ")} Protocol Template",
        matchers: [normalized_key],
        status: "active"
      )

      sync_documents!(template, empty_stack_documents_for(normalized_key))
      template.reload
    end

    private

    attr_reader :registry

    def ensure_seeded!
      seed_common_template!
      seed_stack_templates!
    end

    def seed_common_template!
      template = ProjectProtocolTemplate.find_or_initialize_by(template_kind: "common", key: "common")
      if template.new_record?
        template.name = "Common Protocol Template"
        template.matchers = []
        template.status = "active"
        template.save!
      end
      sync_documents!(template, registry.common_documents)
      template
    end

    def seed_stack_templates!
      registry.stack_templates.each_value do |definition|
        template = ProjectProtocolTemplate.find_or_initialize_by(template_kind: "stack", key: definition.fetch("stack_key"))
        if template.new_record?
          template.name = definition.fetch("name", "#{definition.fetch('stack_key').capitalize} Protocol Template")
          template.matchers = definition.fetch("matchers")
          template.status = "active"
          template.save!
        end
        sync_documents!(template, definition.fetch("documents"))
      end
    end

    def sync_documents!(template, documents)
      existing_keys = template.documents.index_by(&:key)

      documents.each_with_index do |document, index|
        attributes = {
          path: document.fetch("path"),
          title: document.fetch("title"),
          layer: document.fetch("layer"),
          position: document.fetch("position", index)
        }

        if (existing_document = existing_keys[document.fetch("key")])
          existing_document.update!(attributes)
          next
        end

        template.documents.create!(
          key: document.fetch("key"),
          **attributes,
          body: document.fetch("body")
        )
      end
    end

    def empty_stack_documents_for(stack_key)
      registry.stack_template_definition(stack_key).fetch("documents").map do |document|
        document.merge("body" => empty_body_for(document.fetch("title")))
      end
    end

    def empty_body_for(title)
      "# #{title}\n\n"
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
