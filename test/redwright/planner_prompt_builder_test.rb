# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/planner_prompt_builder"

class PlannerPromptBuilderTest < Minitest::Test
  def test_build_includes_required_sections_and_policy
    prompt = Redwright::PlannerPromptBuilder.new.build

    assert_includes(prompt, "[Agent Context]")
    assert_includes(prompt, "[Project Context]")
    assert_includes(prompt, "[Architecture Context]")
    assert_includes(prompt, "[Workspace Context]")
    assert_includes(prompt, "[Precedence Rule]")
    assert_includes(prompt, "[Injection Guardrails]")
    assert_includes(prompt, "[Planner Output Contract]")
    assert_includes(prompt, "Canonical JSON example:")
    assert_includes(prompt, "Output only a single JSON object.")
    assert_includes(prompt, "if uncertain between multiple plausible interpretations, prefer gaps over guessing")
  end

  def test_build_accepts_explicit_context_overrides
    prompt = Redwright::PlannerPromptBuilder.new.build(
      project_context: "Stack: Ruby. Active project: rw.",
      architecture_context: "Use only contracted runtime actions.",
      workspace_context: "Tree: lib/, test/, README.md"
    )

    assert_includes(prompt, "Stack: Ruby. Active project: rw.")
    assert_includes(prompt, "Use only contracted runtime actions.")
    assert_includes(prompt, "Tree: lib/, test/, README.md")
  end
end
