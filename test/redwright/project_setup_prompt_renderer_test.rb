# frozen_string_literal: true

require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/project_setup_prompt_renderer"

class ProjectSetupPromptRendererTest < Minitest::Test
  Completion = Struct.new(:content, :finish_reason, keyword_init: true)

  class FakeLlmClient
    attr_reader :calls

    def initialize(message)
      @message = message
      @calls = []
    end

    def configured?
      true
    end

    def complete_json(model:, system_prompt:, user_text:)
      @calls << {
        model: model,
        system_prompt: system_prompt,
        user_text: JSON.parse(user_text)
      }
      Completion.new(content: JSON.generate({"message" => @message}), finish_reason: "stop")
    end
  end

  class FailingLlmClient
    def configured?
      true
    end

    def complete_json(model:, system_prompt:, user_text:)
      raise "renderer failure"
    end
  end

  def test_renders_setup_prompt_through_configured_llm
    llm = FakeLlmClient.new("Which project archetype should I use?")
    renderer = Redwright::ProjectSetupPromptRenderer.new(llm_client: llm, model: "example/model")

    message = renderer.render(
      body: {
        "status" => "ok",
        "summary" => "Project setup started.",
        "data" => {
          "next_prompt_intent" => {
            "kind" => "setup_slot_question",
            "slot" => "project_type",
            "locale" => "auto",
            "llm_required" => true
          },
          "setup_context" => {
            "slots" => {
              "project_name" => {
                "value" => "pocket-ledger"
              }
            }
          }
        }
      },
      user_text: "/project new pocket-ledger",
      trace_id: "trc-test"
    )

    assert_equal "Which project archetype should I use?", message
    assert_equal "example/model", llm.calls.first.fetch(:model)
    assert_equal "project_type", llm.calls.first.dig(:user_text, "next_prompt_intent", "slot")
    refute_match(/\bTrace:/, message)
    refute_match(/\bState:/, message)
  end

  def test_sanitizes_colon_shortcode_tokens_from_llm_output
    llm = FakeLlmClient.new(":gear: What framework should I use for this project? :keyboard_icon:")
    renderer = Redwright::ProjectSetupPromptRenderer.new(llm_client: llm, model: "example/model")

    message = renderer.render(
      body: {
        "status" => "ok",
        "summary" => "Project setup started.",
        "data" => {
          "next_prompt_intent" => {
            "kind" => "setup_slot_question",
            "slot" => "framework",
            "locale" => "auto",
            "llm_required" => true
          }
        }
      },
      user_text: "Use Ruby",
      trace_id: "trc-test"
    )

    refute_match(/:[a-z0-9_+-]+:/i, message)
    assert_match "What framework should I use for this project?", message
  end

  def test_completion_includes_workspace_when_available
    renderer = Redwright::ProjectSetupPromptRenderer.new

    message = renderer.render(
      body: {
        "status" => "ok",
        "state" => "completed",
        "project_id" => 77,
        "data" => {
          "project" => {
            "id" => 77,
            "name" => "workspace-cli"
          },
          "workspace" => {
            "relative_path" => "_workspace/Projects/workspace-cli"
          }
        }
      },
      user_text: "/done",
      trace_id: "trc-test"
    )

    assert_match "workspace-cli (77)", message
    assert_match "_workspace/Projects/workspace-cli", message
    refute_match(/:[a-z0-9_+-]+:/i, message)
  end

  def test_completion_sanitizes_workspace_shortcode_artifacts
    renderer = Redwright::ProjectSetupPromptRenderer.new

    message = renderer.render(
      body: {
        "status" => "ok",
        "state" => "completed",
        "project_id" => 77,
        "data" => {
          "project" => {
            "id" => 77,
            "name" => "workspace-cli"
          },
          "workspace" => {
            "relative_path" => ":folder: _workspace/Projects/workspace-cli"
          }
        }
      },
      user_text: "/done",
      trace_id: "trc-test"
    )

    assert_match "_workspace/Projects/workspace-cli", message
    refute_match(/:[a-z0-9_+-]+:/i, message)
  end


  def test_falls_back_to_human_prompt_without_llm
    renderer = Redwright::ProjectSetupPromptRenderer.new

    message = renderer.render(
      body: {
        "status" => "ok",
        "summary" => "Project setup started.",
        "data" => {
          "next_prompt_intent" => {
            "kind" => "setup_slot_question",
            "slot" => "language_runtime",
            "locale" => "auto",
            "llm_required" => true
          }
        }
      },
      user_text: "/project new pocket-ledger",
      trace_id: "trc-test"
    )

    assert_match "What primary language or runtime should this project use?", message
    refute_match(/\bTrace:/, message)
    refute_match(/\bSession:/, message)
  end

  def test_fallback_prompt_includes_understood_context_and_controls
    renderer = Redwright::ProjectSetupPromptRenderer.new

    message = renderer.render(
      body: {
        "status" => "ok",
        "summary" => "Project setup started.",
        "data" => {
          "next_prompt_intent" => {
            "kind" => "setup_slot_question",
            "slot" => "project_type",
            "locale" => "auto",
            "llm_required" => true
          },
          "setup_context" => {
            "slots" => {
              "project_name" => {"value" => "pocket-ledger"},
              "description" => {"value" => "A compact ledger for local notes."}
            }
          }
        }
      },
      user_text: "/project new pocket-ledger",
      trace_id: "trc-test"
    )

    assert_match "Project: pocket-ledger", message
    assert_match "Description: A compact ledger for local notes.", message
    assert_match "What type of project", message
    assert_match "/done", message
  end

  def test_fallback_questions_cover_compact_trunk_slots
    renderer = Redwright::ProjectSetupPromptRenderer.new
    expected = {
      "project_name" => "What should I call this project?",
      "description" => "What should this project do?",
      "stack" => "What stack should I assume for this project?",
      "framework" => "What framework should this project use, if any?",
      "libraries" => "What main libraries or services should I include or expect?",
      "repository" => "Do you want to attach a repository URL or owner/repo now?",
      "unknown" => "What else should I know before creating this project?"
    }

    expected.each do |slot, question|
      message = renderer.render(
        body: {
          "status" => "ok",
          "data" => {
            "next_prompt_intent" => {
              "kind" => "setup_slot_question",
              "slot" => slot
            }
          }
        },
        user_text: "setup",
        trace_id: "trc-test"
      )

      assert_match question, message
    end
  end

  def test_falls_back_when_llm_renderer_fails
    renderer = Redwright::ProjectSetupPromptRenderer.new(llm_client: FailingLlmClient.new, model: "example/model")

    message = renderer.render(
      body: {
        "status" => "ok",
        "data" => {
          "next_prompt_intent" => {
            "kind" => "setup_slot_question",
            "slot" => "framework"
          }
        }
      },
      user_text: "setup",
      trace_id: "trc-test"
    )

    assert_match "What framework should this project use, if any?", message
  end

  def test_renders_non_prompt_summary_and_completion_without_project_name
    renderer = Redwright::ProjectSetupPromptRenderer.new(debug: true)

    summary = renderer.render(
      body: {
        "status" => "ok",
        "summary" => "Project setup is waiting for more context."
      },
      user_text: "setup",
      trace_id: "trc-test"
    )
    completion = renderer.render(
      body: {
        "status" => "ok",
        "state" => "completed",
        "project_id" => 77,
        "data" => {
          "project" => {
            "id" => 77
          }
        }
      },
      user_text: "/done",
      trace_id: "trc-test"
    )

    assert_match "Project setup is waiting for more context.", summary
    assert_match "Trace: trc-test", summary
    assert_match "project 77", completion
  end
end
