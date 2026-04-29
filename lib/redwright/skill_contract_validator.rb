# frozen_string_literal: true

module Redwright
  class SkillContractValidator
    Result = Struct.new(:valid, :errors, keyword_init: true)

    def validate(manifest:, input:)
      contracts = manifest&.contracts || {}
      required = Array(contracts["required_fields"]).map(&:to_s)
      missing = required.select { |field| input[field].to_s.strip.empty? }

      errors = []
      errors << "dry_run_not_supported" if input["dry_run"] == true && contracts["dry_run_supported"] != true
      errors.concat(missing.map { |field| "missing_required_field:#{field}" })

      Result.new(valid: errors.empty?, errors: errors)
    end
  end
end
