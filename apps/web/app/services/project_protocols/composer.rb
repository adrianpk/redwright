module ProjectProtocols
  class Composer
    Result = Struct.new(
      :input,
      :documents,
      :stack_keys,
      :fallback_used,
      :missing_stack_tokens,
      keyword_init: true
    ) do
      def to_state
        {
          "input" => input,
          "documents" => documents,
          "stack_keys" => stack_keys,
          "fallback_used" => fallback_used,
          "missing_stack_tokens" => missing_stack_tokens
        }
      end
    end

    def initialize(project:, registry: TemplateCatalog.new)
      @project = project
      @registry = registry
    end

    def call
      tokens = stack_tokens
      selected = tokens.filter_map { |token| template_for(token) }
      matched_keys = selected.map { |template| template.fetch("stack_key") }.uniq
      missing = tokens.reject do |token|
        selected.any? { |template| template.fetch("matchers").any? { |matcher| token.downcase.include?(matcher) } }
      end

      documents = compose_documents(common_documents: registry.common_documents, stack_templates: selected)
      documents = apply_fallback(documents, missing) if missing.any?

      Result.new(
        input: composition_input(tokens, matched_keys),
        documents: documents,
        stack_keys: matched_keys,
        fallback_used: missing.any?,
        missing_stack_tokens: missing
      )
    end

    private

    attr_reader :project, :registry

    def template_for(token)
      return nil if token.to_s.strip.empty?

      normalized = token.to_s.downcase
      registry.stack_templates.values.find do |template|
        template.fetch("matchers").any? { |matcher| normalized.include?(matcher) }
      end
    end

    def compose_documents(common_documents:, stack_templates:)
      merged = common_documents.index_by { |document| document.fetch("key") }

      stack_templates.each do |template|
        template.fetch("documents").each do |document|
          key = document.fetch("key")
          common = merged.fetch(key, document.merge("position" => stack_overlay_position(key, document)))
          merged[key] = common.merge(
            "layer" => document.fetch("layer"),
            "body" => document.fetch("body"),
            "provenance" => {
              "source" => "stack_template",
              "stack_key" => template.fetch("stack_key")
            }
          )
        end
      end

      merged.values.sort_by { |document| document.fetch("position", 999) }.map do |document|
        document.merge(
          "provenance" => document.fetch("provenance", {"source" => "common_template"})
        )
      end
    end

    def stack_overlay_position(key, document)
      return 2 if key == "architecture"

      document.fetch("position", 999)
    end

    def apply_fallback(documents, missing_tokens)
      documents.map do |document|
        next document unless %w[architecture conventions].include?(document.fetch("key"))

        fallback_body = [
          document.fetch("body"),
          "",
          "## Initialization Notes",
          "",
          "This document was expanded during initialization because no seeded stack template matched: #{missing_tokens.join(', ')}.",
          "Treat this content as a minimal starting point and refine it later from Rails."
        ].join("\n")

        document.merge(
          "body" => fallback_body,
          "provenance" => {
            "source" => "generated_during_initialization",
            "missing_stack_tokens" => missing_tokens
          }
        )
      end
    end

    def composition_input(tokens, matched_keys)
      {
        "project_id" => project.id,
        "stack_slug" => project.stack_slug,
        "tokens" => tokens,
        "matched_stack_keys" => matched_keys
      }
    end

    def stack_tokens
      values = [
        project.stack_slug,
        setup_slot("language_runtime"),
        setup_slot("framework")
      ]

      values
        .flat_map { |value| value.to_s.split(/[,\n]/) }
        .map(&:strip)
        .reject { |value| ignorable_token?(value) }
        .reject(&:empty?)
        .uniq
    end

    def setup_slot(slot)
      project.project_attributes.find_by(key: "setup_context.#{slot}")&.value.to_s
    end

    def ignorable_token?(value)
      %w[none omitted unknown unspecified n/a].include?(value.to_s.strip.downcase)
    end
  end
end
