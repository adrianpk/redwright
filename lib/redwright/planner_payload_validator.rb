# frozen_string_literal: true

require "json"
require_relative "planner_contract"

module Redwright
  class PlannerPayloadValidator
    ValidationResult = Struct.new(
      :valid,
      :intent,
      :message,
      :actions,
      :gaps,
      :control_intent,
      :control_scope,
      :operational_intent,
      :operational_scope,
      :operational_args,
      :operational_requires_project,
      :operational_requires_confirmation,
      :skill_requested,
      :skill_mode,
      :skill_actions,
      :skill_exit_condition,
      :errors,
      keyword_init: true
    )

    SCHEMA_PATH = File.expand_path("../../config/schemas/planner_output.schema.json", __dir__)

    def validate(raw_output)
      parsed = normalize_defaults(JSON.parse(raw_output.to_s))
      errors = schema_errors(parsed, schema)
      errors.concat(taxonomy_errors(parsed))
      return invalid(errors) unless errors.empty?

      ValidationResult.new(
        valid: true,
        intent: parsed["intent"].to_s.strip,
        message: parsed["message"].to_s.strip,
        actions: parsed["actions"],
        gaps: parsed["gaps"],
        control_intent: parsed["control_intent"].to_s.strip,
        control_scope: parsed["control_scope"].to_s.strip,
        operational_intent: parsed["operational_intent"].to_s.strip,
        operational_scope: parsed["operational_scope"].to_s.strip,
        operational_args: parsed["operational_args"].is_a?(Hash) ? parsed["operational_args"] : {},
        operational_requires_project: parsed["operational_requires_project"] == true,
        operational_requires_confirmation: parsed["operational_requires_confirmation"] == true,
        skill_requested: parsed["skill_requested"].to_s,
        skill_mode: parsed["skill_mode"].to_s.strip,
        skill_actions: parsed["skill_actions"],
        skill_exit_condition: parsed["skill_exit_condition"].to_s,
        errors: []
      )
    rescue JSON::ParserError => e
      invalid(["invalid_json:#{e.message}"])
    end

    private

    def schema
      @schema ||= JSON.parse(File.read(SCHEMA_PATH))
    end

    def schema_errors(value, schema_node, path = "$")
      node = resolve_ref(schema_node)
      errors = []

      if node.key?("oneOf")
        branch_errors = node["oneOf"].map { |candidate| schema_errors(value, candidate, path) }
        return [] if branch_errors.any?(&:empty?)

        return ["schema_one_of_mismatch:#{path}"]
      end

      if node.key?("type")
        type_ok = type_match?(value, node["type"])
        return ["schema_type_mismatch:#{path}:expected_#{node['type']}"] unless type_ok
      end

      if node["type"] == "object"
        if node["required"].is_a?(Array)
          missing = node["required"].reject { |key| value.key?(key) }
          missing.each { |key| errors << "schema_missing_key:#{path}.#{key}" }
        end

        if node["additionalProperties"] == false && node["properties"].is_a?(Hash)
          extra = value.keys - node["properties"].keys
          extra.each { |key| errors << "schema_extra_key:#{path}.#{key}" }
        end

        if node["properties"].is_a?(Hash)
          node["properties"].each do |key, child_schema|
            next unless value.key?(key)

            errors.concat(schema_errors(value[key], child_schema, "#{path}.#{key}"))
          end
        end

        if node["additionalProperties"].is_a?(Hash)
          allowed = node["properties"].is_a?(Hash) ? node["properties"].keys : []
          (value.keys - allowed).each do |key|
            errors.concat(schema_errors(value[key], node["additionalProperties"], "#{path}.#{key}"))
          end
        end
      elsif node["type"] == "array"
        if node["minItems"].is_a?(Integer) && value.length < node["minItems"]
          errors << "schema_min_items:#{path}:#{node['minItems']}"
        end

        if node["items"].is_a?(Hash)
          value.each_with_index do |item, idx|
            errors.concat(schema_errors(item, node["items"], "#{path}[#{idx}]"))
          end
        end
      elsif node["type"] == "string"
        if node["minLength"].is_a?(Integer) && value.length < node["minLength"]
          errors << "schema_min_length:#{path}:#{node['minLength']}"
        end
      elsif node["type"] == "integer"
        if node["minimum"].is_a?(Numeric) && value < node["minimum"]
          errors << "schema_minimum:#{path}:#{node['minimum']}"
        end
        if node["maximum"].is_a?(Numeric) && value > node["maximum"]
          errors << "schema_maximum:#{path}:#{node['maximum']}"
        end
      end

      if node["enum"].is_a?(Array) && !node["enum"].include?(value)
        errors << "schema_enum_mismatch:#{path}:#{value}"
      end

      errors
    end

    def resolve_ref(schema_node)
      return schema_node unless schema_node.is_a?(Hash) && schema_node["$ref"].is_a?(String)

      ref = schema_node["$ref"]
      return schema_node unless ref.start_with?("#/")

      segments = ref.sub("#/", "").split("/")
      segments.reduce(schema) { |acc, seg| acc.fetch(seg) }
    end

    def type_match?(value, expected)
      case expected
      when "object" then value.is_a?(Hash)
      when "array" then value.is_a?(Array)
      when "string" then value.is_a?(String)
      when "integer" then value.is_a?(Integer)
      when "boolean" then value == true || value == false
      else false
      end
    end

    def invalid(errors)
      ValidationResult.new(
        valid: false,
        intent: nil,
        message: nil,
        actions: nil,
        gaps: nil,
        control_intent: nil,
        control_scope: nil,
        operational_intent: nil,
        operational_scope: nil,
        operational_args: nil,
        operational_requires_project: nil,
        operational_requires_confirmation: nil,
        skill_requested: nil,
        skill_mode: nil,
        skill_actions: nil,
        skill_exit_condition: nil,
        errors: errors
      )
    end

    def normalize_defaults(parsed)
      return parsed unless parsed.is_a?(Hash)

      normalized = parsed.dup
      normalized["control_intent"] = "none" unless normalized.key?("control_intent")
      normalized["control_scope"] = "none" unless normalized.key?("control_scope")
      normalized["operational_intent"] = "none" unless normalized.key?("operational_intent")
      normalized["operational_scope"] = "none" unless normalized.key?("operational_scope")
      normalized["operational_args"] = {} unless normalized.key?("operational_args")
      normalized["operational_requires_project"] = false unless normalized.key?("operational_requires_project")
      normalized["operational_requires_confirmation"] = false unless normalized.key?("operational_requires_confirmation")
      normalized["skill_requested"] = "" unless normalized.key?("skill_requested")
      normalized["skill_mode"] = "none" unless normalized.key?("skill_mode")
      normalized["skill_actions"] = [] unless normalized.key?("skill_actions")
      normalized["skill_exit_condition"] = "" unless normalized.key?("skill_exit_condition")
      normalized
    end

    def taxonomy_errors(parsed)
      errors = []
      control_intent = parsed["control_intent"].to_s
      operational_intent = parsed["operational_intent"].to_s
      operational_scope = parsed["operational_scope"].to_s
      operational_args = parsed["operational_args"]
      requires_project = parsed["operational_requires_project"] == true

      if operational_intent != "none" && control_intent != "none"
        errors << "taxonomy_conflict:control_and_operational_intents"
      end
      if control_intent != "none" && operational_intent != "none"
        errors << "taxonomy_conflict:operational_and_control_intents"
      end
      if operational_intent != "none" && operational_scope == "none"
        errors << "taxonomy_missing_scope_for_operational_intent"
      end
      if requires_project
        unless operational_args.is_a?(Hash) && operational_args["project_ref"].to_s.strip != ""
          errors << "taxonomy_missing_operational_project_ref"
        end
      end

      errors
    end
  end
end
