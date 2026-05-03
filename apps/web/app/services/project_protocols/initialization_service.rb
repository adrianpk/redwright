module ProjectProtocols
  class InitializationService
    Result = Struct.new(
      :project,
      :protocol_state,
      :generated_state,
      :persisted,
      :stack_keys,
      :fallback_used,
      :missing_stack_tokens,
      keyword_init: true
    ) do
      def persisted?
        persisted == true
      end
    end

    def initialize(project:, persist: true, registry: TemplateRegistry.new)
      @project = project
      @persist = persist
      @registry = registry
    end

    def call
      composition = Composer.new(project: project, registry: registry).call
      generated_state = {"status" => "generated", "documents" => composition.documents}

      if persist && project.protocol.nil?
        protocol = project.build_protocol(status: "draft")
        protocol.save!
        composition.documents.each do |document|
          protocol.documents.create!(
            key: document.fetch("key"),
            path: document.fetch("path"),
            title: document.fetch("title"),
            layer: document.fetch("layer"),
            position: document.fetch("position"),
            body: document.fetch("body"),
            provenance: document.fetch("provenance", {})
          )
        end

        return Result.new(
          project: project,
          protocol_state: protocol.reload.to_state,
          generated_state: generated_state,
          persisted: true,
          stack_keys: composition.stack_keys,
          fallback_used: composition.fallback_used,
          missing_stack_tokens: composition.missing_stack_tokens
        )
      end

      Result.new(
        project: project,
        protocol_state: project.protocol_state,
        generated_state: generated_state,
        persisted: false,
        stack_keys: composition.stack_keys,
        fallback_used: composition.fallback_used,
        missing_stack_tokens: composition.missing_stack_tokens
      )
    end

    private

    attr_reader :project, :persist, :registry
  end
end
