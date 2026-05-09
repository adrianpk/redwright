require "json"
require "pathname"
require "securerandom"

begin
  repo_lib = Rails.root.join("../..", "lib").expand_path.to_s
  $LOAD_PATH.unshift(repo_lib) unless $LOAD_PATH.include?(repo_lib)
  require "redwright/app_config"
  require "redwright/llm/context_section"
  require "redwright/llm/context_policy"
  require "redwright/llm/redactor"
  require "redwright/llm/request_engine"
  require "redwright/llm/trace_recorder"
  require "redwright/llm_client_registry"
  require "redwright/model_resolver"
rescue LoadError
  # The provider keeps deterministic fallback behavior when the shared LLM stack is unavailable.
end

module QuizLoops
  class QuestionProvider
    FALLBACK_QUESTION = "What should this project preserve or clarify next?".freeze
    FALLBACK_TAGS = %w[project-context].freeze
    DEEP_ACTION = "quiz_question_generation".freeze
    FAST_ACTION = "quiz_fast_question_generation".freeze
    DEEP_STRATEGY = "deep".freeze
    FAST_STRATEGY = "batch".freeze
    FAST_BATCH_SIZE = 10
    MODEL_ROLE = "non_coding".freeze
    SOURCE_CHANNEL = "quiz_loop".freeze
    DEEP_SYSTEM_PROMPT = <<~TEXT
      You generate exactly one next question for a RedWright project quiz.
      Use the provided project, quiz, recent answer, and routing state context.
      Ask one concise question that helps capture useful project or use-case knowledge.
      Prefer useful progression over repeating prior questions.
      If follow-up depth is high, return to broader coverage.
      Do not ask for secrets, credentials, tokens, passwords, private keys, or PII.
      Return strict JSON with exactly these keys: question, tags, follow_up_depth, completion_recommended.
      tags must be a short array of product/context tags.
      follow_up_depth must be an integer.
      completion_recommended must be a boolean.
    TEXT
    FAST_SYSTEM_PROMPT = <<~TEXT
      You generate the next #{FAST_BATCH_SIZE} questions for a RedWright project quiz fast mode.
      Use the provided project, quiz, recent answer, and routing state context.
      Prefer low-latency questions that can safely advance the quiz without exposing strategy internals.
      Do not mention batch, round, tree, candidate, or strategy choices to the user.
      If the next step needs semantic interpretation that is not explicit in the provided context, return a normal broad question.
      Do not ask for secrets, credentials, tokens, passwords, private keys, or PII.
      Return strict JSON with exactly one key: questions.
      questions must be an array of #{FAST_BATCH_SIZE} objects.
      Each object must have exactly these keys: question, tags, follow_up_depth, completion_recommended.
      tags must be a short array of product/context tags.
      follow_up_depth must be an integer.
      completion_recommended must be a boolean.
    TEXT

    Result = Struct.new(
      :usable,
      :question,
      :tags,
      :follow_up_depth,
      :completion_recommended,
      :prompt_intent,
      :fallback_reason,
      :errors,
      :generation_strategy,
      :candidates,
      keyword_init: true
    ) do
      def usable?
        usable == true
      end
    end

    def initialize(request_engine: default_request_engine, contract: QuestionContract.new, model: default_model, provider: default_provider, trace_recorder: default_trace_recorder)
      @request_engine = request_engine
      @contract = contract
      @model = model.to_s
      @provider = provider.to_s
      @trace_recorder = trace_recorder
    end

    def generate(input:)
      return fallback_result(reason: "llm_unavailable", errors: ["LLM request engine is not configured"]) unless request_engine

      return fast_or_deep_result(input) if fast_mode?(input)

      deep_result(input)
    rescue StandardError => e
      fallback_result(reason: "llm_unavailable", errors: [e.message])
    end

    private

    attr_reader :request_engine, :contract, :model, :provider, :trace_recorder

    def fast_or_deep_result(input)
      fast = fast_result(input)
      return fast if fast&.usable?

      deep_result(input)
    end

    def fast_result(input)
      validated_result(input: input, action: FAST_ACTION, system_prompt: FAST_SYSTEM_PROMPT)
    rescue StandardError
      nil
    end

    def deep_result(input)
      validated_result(input: input, action: DEEP_ACTION, system_prompt: DEEP_SYSTEM_PROMPT) ||
        fallback_result(reason: "llm_unavailable", errors: ["LLM request engine did not return a usable response"])
    end

    def validated_result(input:, action:, system_prompt:)
      response = generate_with_request_engine(input, action: action, system_prompt: system_prompt)
      return fallback_result(reason: "llm_unavailable", errors: response.warnings) unless response.ok?

      return validated_fast_batch_result(response.semantic_payload) if action == FAST_ACTION

      validation = contract.validate(response.semantic_payload)
      return usable_result(validation.attributes, generation_strategy: generation_strategy_for(action)) if validation.valid?

      fallback_result(reason: "llm_malformed", errors: validation.errors)
    end

    def validated_fast_batch_result(output)
      normalized = stringify_hash(output)
      questions = normalized["questions"]
      return fallback_result(reason: "llm_malformed", errors: ["questions must be an array"]) unless questions.is_a?(Array)

      validations = questions.first(FAST_BATCH_SIZE).map { |question| contract.validate(question) }
      errors = validations.flat_map(&:errors)
      return fallback_result(reason: "llm_malformed", errors: errors) if validations.empty? || errors.any?

      candidates = validations.map(&:attributes)
      first = candidates.first
      usable_result(first, generation_strategy: FAST_STRATEGY, candidates: candidates)
    end

    def fast_mode?(input)
      quiz = input["quiz"].is_a?(Hash) ? input["quiz"] : {}
      quiz["mode"].to_s == "fast"
    end

    def usable_result(attributes, generation_strategy:, candidates: [attributes])
      Result.new(
        usable: true,
        question: attributes.fetch("question"),
        tags: attributes.fetch("tags"),
        follow_up_depth: attributes.fetch("follow_up_depth"),
        completion_recommended: attributes.fetch("completion_recommended"),
        prompt_intent: prompt_intent_for(attributes),
        fallback_reason: "",
        errors: [],
        generation_strategy: generation_strategy,
        candidates: candidates
      )
    end

    def fallback_result(reason:, errors:, generation_strategy: DEEP_STRATEGY)
      attributes = {
        "question" => FALLBACK_QUESTION,
        "tags" => FALLBACK_TAGS,
        "follow_up_depth" => 1,
        "completion_recommended" => false
      }
      Result.new(
        usable: false,
        question: attributes.fetch("question"),
        tags: attributes.fetch("tags"),
        follow_up_depth: attributes.fetch("follow_up_depth"),
        completion_recommended: attributes.fetch("completion_recommended"),
        prompt_intent: prompt_intent_for(attributes),
        fallback_reason: reason,
        errors: errors,
        generation_strategy: generation_strategy,
        candidates: [attributes]
      )
    end

    def generation_strategy_for(action)
      action == FAST_ACTION ? FAST_STRATEGY : DEEP_STRATEGY
    end

    def stringify_hash(value)
      return {} unless value.is_a?(Hash)

      value.each_with_object({}) do |(key, item), hash|
        hash[key.to_s] = item
      end
    end

    def prompt_intent_for(attributes)
      PromptIntentBuilder.question(
        question: attributes.fetch("question"),
        tags: attributes.fetch("tags"),
        follow_up_depth: attributes.fetch("follow_up_depth"),
        completion_recommended: attributes.fetch("completion_recommended"),
        routing_state: attributes.fetch("routing_state", {})
      )
    end

    def generate_with_request_engine(input, action:, system_prompt:)
      payload = request_payload(input, action: action)
      user_text = JSON.generate(payload)
      context_sections = context_sections_for(input)
      trace_metadata = trace_metadata_for(input)
      context_policy = context_policy_name_for(action)
      llm_call_id = record_request(
        user_text: user_text,
        context_sections: context_sections,
        trace_metadata: trace_metadata,
        action: action,
        system_prompt: system_prompt,
        context_policy: context_policy
      )
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = request_engine.generate_structured_message(
        model: model,
        model_role: MODEL_ROLE,
        provider: provider,
        action: action,
        system_prompt: system_prompt,
        user_text: user_text,
        output_contract: output_contract_for(action),
        context_sections: context_sections,
        context_policy: context_policy,
        dynamic_context_policy: true,
        trace_metadata: trace_metadata
      )
      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).to_i
      record_response(response: response, llm_call_id: llm_call_id, elapsed_ms: elapsed_ms, trace_metadata: trace_metadata, action: action)
      response
    end

    def request_payload(input, action:)
      {
        "project" => input["project"] || {},
        "quiz" => input["quiz"] || {},
        "recent_entries" => input["recent_entries"] || [],
        "current_question" => input["current_question"] || {},
        "output_contract" => output_contract_for(action)
      }
    end

    def output_contract
      deep_output_contract
    end

    def output_contract_for(action)
      action == FAST_ACTION ? fast_output_contract : deep_output_contract
    end

    def deep_output_contract
      {
        "required_fields" => QuestionContract::REQUIRED_FIELDS,
        "rendered_text_field" => "question"
      }
    end

    def fast_output_contract
      {
        "required_fields" => ["questions"],
        "rendered_text_field" => "questions"
      }
    end

    def context_sections_for(input)
      return [] unless defined?(Redwright::LLM::ContextSection)

      [
        Redwright::LLM::ContextSection.new(name: "project", content: input["project"] || {}, authority: "project_context", metadata: {"context_layer" => "project"}),
        Redwright::LLM::ContextSection.new(name: "quiz", content: input["quiz"] || {}, authority: "request_context", metadata: {"context_layer" => "quizzes"}),
        Redwright::LLM::ContextSection.new(name: "recent_entries", content: input["recent_entries"] || [], authority: "quiz_context", metadata: {"context_layer" => "quizzes"}),
        Redwright::LLM::ContextSection.new(name: "current_question", content: input["current_question"] || {}, authority: "request_context", metadata: {"context_layer" => "quizzes"})
      ]
    end

    def trace_metadata_for(input)
      project = input["project"].is_a?(Hash) ? input["project"] : {}
      quiz = input["quiz"].is_a?(Hash) ? input["quiz"] : {}
      {
        trace_id: trace_id,
        project_id: project["id"],
        session_id: quiz["id"],
        source_channel: SOURCE_CHANNEL
      }
    end

    def trace_id
      return Redwright::Trace.current_trace_id if defined?(Redwright::Trace) && Redwright::Trace.current_trace_id

      "quiz-#{SecureRandom.hex(4)}"
    end

    def context_policy_name_for(action)
      return nil unless defined?(Redwright::LLM::ContextPolicy)

      Redwright::LLM::ContextPolicy.policy_name_for_action(action)
    end

    def policy_decision_for_trace(context_policy)
      return nil unless defined?(Redwright::LLM::ContextPolicy)

      policy = Redwright::LLM::ContextPolicy.fetch_policy(context_policy)
      return nil unless policy

      {
        policy_name: policy.name,
        work_family: policy.work_family,
        fallback: policy.fallback?,
        included_layers: policy.included_layers
      }
    end

    def record_request(user_text:, context_sections:, trace_metadata:, action:, system_prompt:, context_policy:)
      return nil unless trace_recorder

      safe_user_text = if defined?(Redwright::LLM::Redactor)
                         Redwright::LLM::Redactor.redact_text(user_text)
                       else
                         user_text
                       end
      trace_recorder.record_request(
        model_role: MODEL_ROLE,
        provider: provider,
        model: model,
        model_alias: model,
        action: action,
        payload_bytes: safe_user_text.bytesize,
        system_prompt: system_prompt,
        user_text: safe_user_text,
        trace_id: trace_metadata.fetch(:trace_id),
        project_id: trace_metadata[:project_id],
        session_id: trace_metadata[:session_id],
        source_channel: SOURCE_CHANNEL,
        context_summary: "Quiz next-question generation.",
        context_bytes: safe_user_text.bytesize,
        context_sections: context_sections.map(&:to_h),
        policy_decision: policy_decision_for_trace(context_policy)
      )
    end

    def record_response(response:, llm_call_id:, elapsed_ms:, trace_metadata:, action:)
      return nil unless trace_recorder

      trace_recorder.record_response(
        status: response.ok? ? "ok" : "fallback",
        llm_call_id: llm_call_id,
        latency_ms: elapsed_ms,
        output_bytes: response.raw_response_ref.to_s.bytesize,
        finish_reason: response.provider_metadata[:finish_reason],
        raw_output: response.raw_response_ref,
        parsed_fields: response.semantic_payload,
        decision_source: response.ok? ? "llm" : response.status,
        error: response.ok? ? nil : response.warnings.join("; "),
        trace_id: trace_metadata.fetch(:trace_id),
        project_id: trace_metadata[:project_id],
        session_id: trace_metadata[:session_id],
        source_channel: SOURCE_CHANNEL,
        action: action,
        model_role: MODEL_ROLE,
        provider: provider,
        model: model,
        model_alias: model,
        policy_decision: response.respond_to?(:diagnostics) ? response.diagnostics&.fetch(:context_policy, nil) : nil
      )
    end

    def default_request_engine
      self.class.default_request_engine
    end

    def default_model
      self.class.default_model
    end

    def default_provider
      self.class.default_provider
    end

    def default_trace_recorder
      return Redwright::LLM::TraceRecorder.new if defined?(Redwright::LLM::TraceRecorder)

      nil
    end

    class << self
      def default_request_engine
        default_context.fetch(:request_engine)
      end

      def default_model
        default_context.fetch(:model)
      end

      def default_provider
        default_context.fetch(:provider)
      end

      private

      def default_context
        @default_context ||= build_default_context
      end

      def build_default_context
        return unavailable_context if Rails.env.test?
        return unavailable_context unless defined?(Redwright::AppConfigLoader)

        repo_root = Rails.root.join("../..").expand_path.to_s
        config = Redwright::AppConfigLoader.new(mode: :dev, pwd: repo_root).load(ingress: "none")
        Redwright::Trace.configure(tracing: tracing_for(config, repo_root: repo_root)) if defined?(Redwright::Trace)
        resolved_model = Redwright::ModelResolver.new(config.models).resolve(MODEL_ROLE)
        llm_client = Redwright::LlmClientRegistry.new.client_for(resolved_model.provider)
        {
          request_engine: Redwright::LLM::RequestEngine.new(llm_client: llm_client),
          model: resolved_model.name,
          provider: resolved_model.provider
        }
      rescue StandardError
        unavailable_context
      end

      def tracing_for(config, repo_root:)
        llm_file = config.tracing.llm_file
        return config.tracing unless llm_file && defined?(Redwright::TracingConfig) && defined?(Redwright::LlmFileTraceConfig)

        path = llm_file.path.to_s
        normalized_path = Pathname.new(path).absolute? ? path : File.expand_path(path, repo_root)
        Redwright::TracingConfig.new(
          llm_file: Redwright::LlmFileTraceConfig.new(
            enabled: llm_file.enabled,
            path: normalized_path,
            max_bytes: llm_file.max_bytes,
            keep_files: llm_file.keep_files,
            include_payloads: llm_file.include_payloads,
            include_system_prompt: llm_file.include_system_prompt,
            include_user_text: llm_file.include_user_text,
            include_raw_output: llm_file.include_raw_output
          )
        )
      end

      def unavailable_context
        {
          request_engine: nil,
          model: ENV.fetch("REDWRIGHT_QUIZ_MODEL", "none"),
          provider: ENV.fetch("REDWRIGHT_QUIZ_PROVIDER", "none")
        }
      end
    end
  end
end
