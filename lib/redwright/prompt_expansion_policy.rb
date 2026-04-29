# frozen_string_literal: true

module Redwright
  class PromptExpansionPolicy
    class PromptExpansionError < StandardError; end

    def inline_prompt(prompt:, prompt_args: nil)
      unless prompt_args.nil? || prompt_args.empty?
        raise PromptExpansionError, "prompt_args_not_allowed_for_inline"
      end

      prompt.to_s
    end

    def template_prompt(template:, prompt_args:)
      rendered = template.to_s.dup
      args = stringify_keys(prompt_args || {})

      rendered.scan(/\{\{([A-Z0-9_]+)\}\}/).flatten.each do |key|
        value = args[key]
        raise PromptExpansionError, "missing_prompt_arg:#{key}" if value.nil?

        rendered.gsub!("{{#{key}}}", value.to_s)
      end

      rendered
    end

    private

    def stringify_keys(hash)
      hash.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
    end
  end
end
