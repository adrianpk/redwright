# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/prompt_expansion_policy"

class PromptExpansionPolicyTest < Minitest::Test
  def test_inline_prompt_is_literal
    policy = Redwright::PromptExpansionPolicy.new

    rendered = policy.inline_prompt(prompt: "Fix {{DONT_TOUCH}} !`ls`")

    assert_equal("Fix {{DONT_TOUCH}} !`ls`", rendered)
  end

  def test_inline_prompt_rejects_prompt_args
    policy = Redwright::PromptExpansionPolicy.new

    error = assert_raises(Redwright::PromptExpansionPolicy::PromptExpansionError) do
      policy.inline_prompt(prompt: "hello", prompt_args: { "NAME" => "x" })
    end

    assert_equal("prompt_args_not_allowed_for_inline", error.message)
  end

  def test_template_prompt_expands_declared_placeholders
    policy = Redwright::PromptExpansionPolicy.new

    rendered = policy.template_prompt(
      template: "Move {{TICKET}} to {{COLUMN}}",
      prompt_args: { "TICKET" => "RW-42", "COLUMN" => "review" }
    )

    assert_equal("Move RW-42 to review", rendered)
  end

  def test_template_prompt_rejects_missing_placeholder_values
    policy = Redwright::PromptExpansionPolicy.new

    error = assert_raises(Redwright::PromptExpansionPolicy::PromptExpansionError) do
      policy.template_prompt(template: "Move {{TICKET}}", prompt_args: {})
    end

    assert_equal("missing_prompt_arg:TICKET", error.message)
  end
end
