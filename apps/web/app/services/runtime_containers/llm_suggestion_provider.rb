module RuntimeContainers
  class LlmSuggestionProvider
    Result = Struct.new(:usable, :attributes, :fallback_reason, :errors, keyword_init: true) do
      def usable?
        usable == true
      end
    end

    def initialize(client: nil, contract: LlmGenerationContract.new)
      @client = client
      @contract = contract
    end

    def generate(input:)
      return fallback_result(reason: "llm_unavailable", errors: ["LLM generation client is not configured"]) unless client

      validation = contract.validate(raw_output_for(input))
      return Result.new(usable: true, attributes: validation.attributes, fallback_reason: "", errors: []) if validation.valid?

      fallback_result(reason: "llm_malformed", errors: validation.errors)
    rescue StandardError => e
      fallback_result(reason: "llm_unavailable", errors: [e.message])
    end

    private

    attr_reader :client, :contract

    def raw_output_for(input)
      return client.generate_runtime_container(input: input) if client.respond_to?(:generate_runtime_container)
      return client.call(input: input) if client.respond_to?(:call)

      raise ArgumentError, "LLM generation client does not implement generate_runtime_container or call"
    end

    def fallback_result(reason:, errors:)
      Result.new(usable: false, attributes: {}, fallback_reason: reason, errors: errors)
    end
  end
end
