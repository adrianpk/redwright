# frozen_string_literal: true

require "digest"
require "json"

module Redwright
  class FeedbackNormalizer
    Feedback = Struct.new(
      :normalized_failures,
      :execution_results,
      :fingerprints,
      keyword_init: true
    )

    def normalize(quality_summary:, action_results:)
      failures = []
      execution = []
      fps = []

      Array(action_results).each do |result|
        status = value_for(result, :status)
        action_id = value_for(result, :action_id)
        action_type = value_for(result, :action_type)
        error = value_for(result, :error_message)
        execution << {
          "action_id" => action_id,
          "action_type" => action_type,
          "status" => status,
          "error_message" => error
        }
        next if status == "ok"

        failure_class = classify_action_failure(action_type: action_type, error_message: error)
        fingerprint = build_fingerprint(failure_class: failure_class, detail: "#{action_type}:#{error}")
        failures << "#{failure_class}:#{error}"
        fps << {
          "failure_class" => failure_class,
          "fingerprint" => fingerprint
        }
      end

      if quality_summary.is_a?(Hash)
        failed_checks = Array(quality_summary[:failed_check_names]).map(&:to_s)
        failed_checks.each do |name|
          failure_class = classify_quality_failure(name)
          fingerprint = build_fingerprint(failure_class: failure_class, detail: name)
          failures << "#{failure_class}:#{name}"
          fps << {
            "failure_class" => failure_class,
            "fingerprint" => fingerprint
          }
        end
      end

      Feedback.new(
        normalized_failures: failures.uniq,
        execution_results: execution,
        fingerprints: fps.uniq
      )
    end

    private

    def value_for(obj, field)
      return "" unless obj.respond_to?(field)

      obj.public_send(field).to_s
    rescue StandardError
      ""
    end

    def classify_action_failure(action_type:, error_message:)
      type = action_type.to_s.downcase
      error = error_message.to_s.downcase
      return "test_failure" if type.include?("test") || error.include?("test")
      return "lint_failure" if type.include?("lint") || error.include?("lint")
      return "build_failure" if type.include?("build") || error.include?("compile")

      "action_failure"
    end

    def classify_quality_failure(check_name)
      name = check_name.to_s.downcase
      return "test_failure" if name.include?("test")
      return "lint_failure" if name.include?("lint")

      "validation_failure"
    end

    def build_fingerprint(failure_class:, detail:)
      "fp-#{Digest::SHA256.hexdigest("#{failure_class}:#{detail}")[0, 10]}"
    end
  end
end
