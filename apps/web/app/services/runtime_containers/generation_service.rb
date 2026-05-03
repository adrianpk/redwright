module RuntimeContainers
  class GenerationService
    Result = Struct.new(
      :project,
      :input,
      :runtime_container_state,
      :generated_state,
      :persisted,
      :generator_source,
      :fallback_reason,
      :errors,
      keyword_init: true
    ) do
      def persisted?
        persisted == true
      end
    end

    def initialize(project:, llm_client: nil)
      @project = project
      @llm_client = llm_client
    end

    def call
      input = GenerationInputBuilder.new(project: project).build
      generated = generated_attributes_for(input)
      generated_state = state_from_attributes(generated.fetch("attributes"))
      container = project.runtime_container

      if persistable?(container)
        container ||= project.build_runtime_container
        container.assign_attributes(generated.fetch("attributes"))
        container.save!
        return result_for(
          input: input,
          runtime_container_state: container.reload.to_state,
          generated_state: container.to_state,
          generated: generated,
          persisted: true
        )
      end

      result_for(
        input: input,
        runtime_container_state: container.to_state,
        generated_state: generated_state,
        generated: generated,
        persisted: false
      )
    end

    private

    attr_reader :project, :llm_client

    def generated_attributes_for(input)
      if GoCliGenerator.supported?(input)
        return {
          "attributes" => GoCliGenerator.new(input: input).attributes,
          "generator_source" => "deterministic_go_cli_generator",
          "fallback_reason" => "",
          "errors" => []
        }
      end

      llm_result = LlmSuggestionProvider.new(client: llm_client).generate(input: input)
      if llm_result.usable?
        return {
          "attributes" => llm_result.attributes,
          "generator_source" => "llm_generator",
          "fallback_reason" => "",
          "errors" => []
        }
      end

      {
        "attributes" => UnsupportedGenerator.new(
          input: input,
          fallback_reason: llm_result.fallback_reason,
          llm_errors: llm_result.errors
        ).attributes,
        "generator_source" => "unsupported_context_fallback",
        "fallback_reason" => llm_result.fallback_reason,
        "errors" => llm_result.errors
      }
    end

    def persistable?(container)
      container.nil? || container.readiness == "missing"
    end

    def state_from_attributes(attributes)
      ProjectRuntimeContainer.new(attributes.merge(project: project)).to_state
    end

    def result_for(input:, runtime_container_state:, generated_state:, generated:, persisted:)
      Result.new(
        project: project,
        input: input,
        runtime_container_state: runtime_container_state,
        generated_state: generated_state,
        persisted: persisted,
        generator_source: generated.fetch("generator_source"),
        fallback_reason: generated.fetch("fallback_reason"),
        errors: generated.fetch("errors")
      )
    end
  end
end
