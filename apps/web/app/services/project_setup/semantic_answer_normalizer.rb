module ProjectSetup
  class SemanticAnswerNormalizer
    Result = Struct.new(
      :slot_key,
      :raw_value,
      :value,
      :source,
      :status,
      :confidence,
      :normalization_reason,
      :slot_updates,
      :warnings,
      keyword_init: true
    ) do
      def ambiguous?
        status.to_s == "ambiguous"
      end
    end

    def normalize(slot_key:, answer:, normalized_fields:, setup_context:)
      normalized = normalized_fields.to_h.transform_keys(&:to_s)
      external_value = normalized[slot_key.to_s]
      external_value = normalized["value"] if external_value.to_s.strip.empty?
      if external_value.to_s.strip.present?
        return result(
          slot_key: slot_key,
          raw_value: answer,
          value: external_value,
          source: "normalized_fields",
          reason: "accepted external normalized field",
          slot_updates: auxiliary_updates(normalized, except: slot_key)
        )
      end

      return ambiguous_result(slot_key: slot_key, answer: answer, reason: "answer appears to describe prompt confusion") if prompt_confusion?(answer)

      fallback_value = fallback_value_for(slot_key: slot_key, answer: answer, setup_context: setup_context)
      result(
        slot_key: slot_key,
        raw_value: answer,
        value: fallback_value,
        source: "semantic_normalizer",
        reason: "deterministic fallback normalization",
        slot_updates: inferred_updates(slot_key: slot_key, answer: answer)
      )
    end

    private

    def result(slot_key:, raw_value:, value:, source:, reason:, slot_updates: {}, status: nil, confidence: 1.0, warnings: [])
      cleaned_value = value.to_s.strip
      Result.new(
        slot_key: slot_key.to_s,
        raw_value: raw_value.to_s,
        value: cleaned_value,
        source: source,
        status: status || (cleaned_value.empty? ? "empty" : "filled"),
        confidence: confidence,
        normalization_reason: reason,
        slot_updates: slot_updates,
        warnings: warnings
      )
    end

    def ambiguous_result(slot_key:, answer:, reason:)
      result(
        slot_key: slot_key,
        raw_value: answer,
        value: "",
        source: "semantic_normalizer",
        reason: reason,
        status: "ambiguous",
        confidence: 0.25,
        warnings: [reason]
      )
    end

    def fallback_value_for(slot_key:, answer:, setup_context:)
      raw = answer.to_s.strip
      case slot_key.to_s
      when "project_type"
        normalize_project_type(raw)
      when "language_runtime"
        normalize_language_runtime(raw: raw, setup_context: setup_context)
      when "framework"
        normalize_framework(raw)
      else
        raw
      end
    end

    def normalize_project_type(raw)
      normalized = raw.downcase
      return "cli" if normalized.include?("cli") || normalized.include?("command-line")
      return "api_service" if normalized.include?("api")
      return "web_app" if normalized.include?("web")
      return "library" if normalized.include?("library")
      return "worker" if normalized.include?("worker")

      raw
    end

    def normalize_language_runtime(raw:, setup_context:)
      return "Go #{raw}" if version_only?(raw) && context_mentions?(setup_context, "go")

      normalized = raw.downcase
      return "Go #{version_suffix(raw)}".strip if normalized.match?(/\bgo\b/)
      return "Ruby #{version_suffix(raw)}".strip if normalized.match?(/\bruby\b/)
      return "Node.js #{version_suffix(raw)}".strip if normalized.match?(/\bnode(\.js)?\b/)
      return "Python #{version_suffix(raw)}".strip if normalized.match?(/\bpython\b/)

      raw
    end

    def normalize_framework(raw)
      normalized = raw.downcase.strip
      return "none" if %w[none no n/a not-applicable].include?(normalized)

      raw
    end

    def inferred_updates(slot_key:, answer:)
      return {} unless slot_key.to_s == "project_type"

      normalized = answer.to_s.downcase
      return {"language_runtime" => "Go"} if normalized.match?(/\bgo\b/)
      return {"language_runtime" => "Ruby"} if normalized.match?(/\bruby\b/)
      return {"language_runtime" => "Node.js"} if normalized.match?(/\bnode(\.js)?\b/)
      return {"language_runtime" => "Python"} if normalized.match?(/\bpython\b/)

      {}
    end

    def auxiliary_updates(normalized, except:)
      ProjectSetupSession::SETUP_SLOT_KEYS.each_with_object({}) do |slot_key, updates|
        next if slot_key == except.to_s
        next unless normalized.key?(slot_key)

        value = normalized[slot_key].to_s.strip
        updates[slot_key] = value unless value.empty?
      end
    end

    def prompt_confusion?(answer)
      normalized = answer.to_s.downcase
      normalized.include?("do not understand") ||
        normalized.include?("don't understand") ||
        normalized.include?("what does") ||
        normalized.include?("what those") ||
        normalized.include?("confusing") ||
        normalized.include?("unclear")
    end

    def version_only?(value)
      value.to_s.strip.match?(/\A\d+(?:\.\d+){1,3}\z/)
    end

    def version_suffix(value)
      match = value.to_s.match(/\d+(?:\.\d+){0,3}/)
      match ? match[0] : ""
    end

    def context_mentions?(setup_context, token)
      slots = setup_context.to_h["slots"]
      return false unless slots.is_a?(Hash)

      slots.values.any? do |slot|
        slot.is_a?(Hash) && slot["value"].to_s.downcase.match?(/\b#{Regexp.escape(token)}\b/)
      end
    end
  end
end
