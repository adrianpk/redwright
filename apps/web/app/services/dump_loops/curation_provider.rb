require "json"

begin
  repo_lib = Rails.root.join("../..", "lib").expand_path.to_s
  $LOAD_PATH.unshift(repo_lib) unless $LOAD_PATH.include?(repo_lib)
  require "redwright/llm/context_section"
  require "redwright/llm/redactor"
rescue LoadError
  # The provider keeps deterministic fallback behavior when shared LLM helpers are unavailable.
end

module DumpLoops
  class CurationProvider
    ENTRY_ACTION = "dump_entry_polish".freeze
    CURATION_ACTION = "dump_curation".freeze
    MODEL_ROLE = "non_coding".freeze
    SOURCE_CHANNEL = "dump_loop".freeze
    LOCAL_ASSIGNMENT_SECRET = /\b(api[_-]?(?:key|token)|token|password|secret|credential)=([^\s,"}]+)/i

    ENTRY_SYSTEM_PROMPT = <<~TEXT
      You polish one user-provided RedWright dump entry.
      Preserve the user's intent and useful sequence.
      Correct spelling, punctuation, grammar, and style.
      Do not add interpretation that belongs in curated notes.
      Mark possible derived threads without expanding them into new artifacts.
      Redact obvious secrets, credentials, tokens, passwords, and private keys.
      Return strict JSON with exactly these keys: polished_input, topic_heading, derived_thread_hints, tag_suggestions, warnings.
    TEXT

    CURATION_SYSTEM_PROMPT = <<~TEXT
      You curate a completed RedWright dump.
      Use only the supplied dump entries and metadata.
      Extract structure without inventing unsupported requirements.
      Do not create specs, plans, tickets, or docs.
      Keep hidden reasoning out of the output.
      Return strict JSON with exactly these keys: central_topic, summary, key_concepts, decisions_or_preferences, tensions_and_tradeoffs, assumptions, derived_threads, possible_downstream_artifacts, open_questions, tag_suggestions.
    TEXT

    Result = Struct.new(:usable, :attributes, :fallback_reason, :errors, keyword_init: true) do
      def usable?
        usable == true
      end
    end

    def initialize(request_engine: nil, entry_contract: nil, curated_contract: nil, configuration: Configuration.current, model: "none", provider: "none")
      @request_engine = request_engine
      @configuration = configuration
      @entry_contract = entry_contract || EntryContract.new(max_tags: configuration.max_tags)
      @curated_contract = curated_contract || CuratedDumpContract.new(max_tags: configuration.max_tags)
      @model = model.to_s
      @provider = provider.to_s
    end

    def polish_entry(input:)
      return fallback_entry_result(input, reason: "entry_polishing_disabled", errors: ["Dump entry polishing is disabled"]) unless configuration.entry_polishing_enabled?
      return fallback_entry_result(input, reason: "llm_unavailable", errors: ["LLM request engine is not configured"]) unless request_engine

      response = generate(input, action: ENTRY_ACTION, system_prompt: ENTRY_SYSTEM_PROMPT, output_contract: entry_output_contract)
      return fallback_entry_result(input, reason: "llm_unavailable", errors: response.warnings) unless response.ok?

      validation = entry_contract.validate(response.semantic_payload)
      return Result.new(usable: true, attributes: validation.attributes, fallback_reason: "", errors: []) if validation.valid?

      fallback_entry_result(input, reason: "llm_malformed", errors: validation.errors)
    rescue StandardError => e
      fallback_entry_result(input, reason: "llm_unavailable", errors: [e.message])
    end

    def curate_dump(input:)
      return fallback_curated_result(input, reason: "curation_disabled", errors: ["Dump curation is disabled"]) unless configuration.curation_enabled?
      return fallback_curated_result(input, reason: "llm_unavailable", errors: ["LLM request engine is not configured"]) unless request_engine

      response = generate(input, action: CURATION_ACTION, system_prompt: CURATION_SYSTEM_PROMPT, output_contract: curated_output_contract)
      return fallback_curated_result(input, reason: "llm_unavailable", errors: response.warnings) unless response.ok?

      validation = curated_contract.validate(response.semantic_payload)
      return Result.new(usable: true, attributes: validation.attributes, fallback_reason: "", errors: []) if validation.valid?

      fallback_curated_result(input, reason: "llm_malformed", errors: validation.errors)
    rescue StandardError => e
      fallback_curated_result(input, reason: "llm_unavailable", errors: [e.message])
    end

    private

    attr_reader :request_engine, :entry_contract, :curated_contract, :configuration, :model, :provider

    def generate(input, action:, system_prompt:, output_contract:)
      request_engine.generate_structured_message(
        model: model,
        model_role: MODEL_ROLE,
        provider: provider,
        action: action,
        system_prompt: system_prompt,
        user_text: JSON.generate(request_payload(input, output_contract: output_contract)),
        output_contract: output_contract,
        context_sections: context_sections_for(input)
      )
    end

    def request_payload(input, output_contract:)
      stringify_hash(input).merge("output_contract" => output_contract)
    end

    def entry_output_contract
      {
        "required_fields" => EntryContract::REQUIRED_FIELDS,
        "rendered_text_field" => "polished_input"
      }
    end

    def curated_output_contract
      {
        "required_fields" => CuratedDumpContract::REQUIRED_FIELDS,
        "rendered_text_field" => "summary"
      }
    end

    def context_sections_for(input)
      return [] unless defined?(Redwright::LLM::ContextSection)

      [
        Redwright::LLM::ContextSection.new(name: "project", content: input["project"] || input[:project] || {}, authority: "project_context", metadata: {"context_layer" => "project"}),
        Redwright::LLM::ContextSection.new(name: "dump", content: input["dump"] || input[:dump] || {}, authority: "dump_context", metadata: {"context_layer" => "dumps"}),
        Redwright::LLM::ContextSection.new(name: "dump_entries", content: input["entries"] || input[:entries] || [], authority: "dump_context", metadata: {"context_layer" => "dumps"})
      ]
    end

    def fallback_entry_result(input, reason:, errors:)
      raw_input = stringify_hash(input).fetch("raw_input", "").to_s
      polished = redact_text(raw_input.strip)
      attributes = {
        "polished_input" => polished.presence || "No dump content provided.",
        "topic_heading" => nil,
        "derived_thread_hints" => [],
        "tag_suggestions" => [],
        "warnings" => fallback_warnings(reason, errors)
      }
      Result.new(usable: false, attributes: attributes, fallback_reason: reason, errors: errors)
    end

    def fallback_curated_result(input, reason:, errors:)
      normalized = stringify_hash(input)
      dump = stringify_hash(normalized["dump"] || {})
      body = body_from(normalized)
      title = dump["title"].to_s.strip.presence || "Untitled dump"
      attributes = {
        "central_topic" => title,
        "summary" => summary_from(body),
        "key_concepts" => [],
        "decisions_or_preferences" => [],
        "tensions_and_tradeoffs" => [],
        "assumptions" => [],
        "derived_threads" => [],
        "possible_downstream_artifacts" => [],
        "open_questions" => [],
        "tag_suggestions" => []
      }
      Result.new(usable: false, attributes: attributes, fallback_reason: reason, errors: errors)
    end

    def body_from(input)
      return input["raw_body"].to_s if input["raw_body"].present?

      Array(input["entries"]).map do |entry|
        item = stringify_hash(entry)
        item["polished_input"].presence || item["raw_input"]
      end.compact.join("\n\n")
    end

    def summary_from(body)
      text = redact_text(body.to_s.strip)
      return "No dump content was available for curation." if text.blank?

      text.truncate(240)
    end

    def fallback_warnings(reason, errors)
      ([reason] + Array(errors)).map(&:to_s).reject(&:blank?)
    end

    def redact_text(value)
      redacted = if defined?(Redwright::LLM::Redactor)
                   Redwright::LLM::Redactor.redact_text(value)
                 else
                   value.to_s
                 end

      redacted.gsub(LOCAL_ASSIGNMENT_SECRET) { "#{$1}=#{redacted_marker}" }
    end

    def redacted_marker
      return Redwright::LLM::Redactor::REDACTED if defined?(Redwright::LLM::Redactor::REDACTED)

      "[REDACTED]"
    end

    def stringify_hash(value)
      return {} unless value.is_a?(Hash)

      value.each_with_object({}) do |(key, item), hash|
        hash[key.to_s] = item
      end
    end
  end
end
