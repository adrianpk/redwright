# frozen_string_literal: true

require "json"
require "stringio"
require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/app_config"
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

  class MalformedLlmClient
    def configured?
      true
    end

    def complete_json(model:, system_prompt:, user_text:)
      Completion.new(content: "not json", finish_reason: "stop")
    end
  end

  class RecordingTraceRecorder
    attr_reader :requests, :responses

    def initialize
      @requests = []
      @responses = []
    end

    def record_request(**kwargs)
      @requests << kwargs
      "llm-test"
    end

    def record_response(**kwargs)
      @responses << kwargs
      "llm-test"
    end
  end

  def teardown
    Redwright::Trace.reset_configuration!
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

  def test_traces_configured_llm_prompt_rendering
    llm = FakeLlmClient.new("What type of project should this be?")
    renderer = Redwright::ProjectSetupPromptRenderer.new(llm_client: llm, model: "openrouter/auto")

    out = capture_stdout do
      with_env("REDWRIGHT_TRACE" => "", "REDWRIGHT_TRACE_LLM" => "1") do
        renderer.render(
          body: {
            "status" => "ok",
            "summary" => "Project setup started.",
            "data" => {
              "next_prompt_intent" => {
                "kind" => "setup_slot_question",
                "slot" => "project_type",
                "locale" => "auto",
                "llm_required" => true
              }
            }
          },
          user_text: "/project new pocket-ledger",
          trace_id: "trc-test"
        )
      end
    end

    assert_includes out, "LLM REQUEST"
    assert_includes out, "action: project_setup_prompt_render"
    assert_includes out, "provider: openrouter"
    assert_includes out, "LLM RESPONSE"
    assert_includes out, "parsed_message: What type of project should this be?"
  end

  def test_coordinates_trace_recording_outside_request_engine
    llm = FakeLlmClient.new("What type of project should this be?")
    trace_recorder = RecordingTraceRecorder.new
    renderer = Redwright::ProjectSetupPromptRenderer.new(
      llm_client: llm,
      model: "openrouter/auto",
      trace_recorder: trace_recorder
    )

    renderer.render(
      body: {
        "status" => "ok",
        "project_id" => 77,
        "session_id" => 41,
        "summary" => "Project setup started.",
        "data" => {
          "next_prompt_intent" => {
            "kind" => "setup_slot_question",
            "slot" => "project_type",
            "locale" => "auto",
            "llm_required" => true
          }
        }
      },
      user_text: "/project new pocket-ledger",
      trace_id: "trc-test"
    )

    assert_equal 1, trace_recorder.requests.length
    assert_equal 1, trace_recorder.responses.length
    assert_equal "project_setup_prompt_render", trace_recorder.requests.first.fetch(:action)
    assert_equal "non_coding", trace_recorder.requests.first.fetch(:model_role)
    assert_equal ["setup_summary", "next_prompt_intent", "setup_context", "user_text"], trace_recorder.requests.first.fetch(:context_sections)
    assert_equal "ok", trace_recorder.responses.first.fetch(:status)
    assert_equal "llm", trace_recorder.responses.first.fetch(:decision_source)
  end

  def test_writes_project_setup_llm_trace_file_when_configured
    Dir.mktmpdir("redwright-project-setup-trace-") do |dir|
      Redwright::Trace.configure(
        tracing: Redwright::TracingConfig.new(
          llm_file: Redwright::LlmFileTraceConfig.new(
            enabled: true,
            path: File.join(dir, "llm.ndjson"),
            max_bytes: 10_485_760,
            keep_files: 5,
            include_payloads: true,
            include_system_prompt: false,
            include_user_text: true,
            include_raw_output: true
          )
        )
      )
      llm = FakeLlmClient.new("What type of project should this be?")
      renderer = Redwright::ProjectSetupPromptRenderer.new(llm_client: llm, model: "openrouter/auto")

      renderer.render(
        body: {
          "status" => "ok",
          "project_id" => 77,
          "session_id" => 41,
          "summary" => "Project setup started.",
          "data" => {
            "next_prompt_intent" => {
              "kind" => "setup_slot_question",
              "slot" => "project_type",
              "locale" => "auto",
              "llm_required" => true
            }
          }
        },
        user_text: "/project new pocket-ledger",
        trace_id: "trc-test"
      )

      lines = File.readlines(File.join(dir, "llm.ndjson"), chomp: true)
      request = JSON.parse(lines[0])
      response = JSON.parse(lines[1])
      assert_equal("project_setup", request.fetch("source_channel"))
      assert_equal(77, request.fetch("project_id"))
      assert_equal(41, request.fetch("session_id"))
      assert_equal("trc-test", request.fetch("trace_id"))
      assert_equal(request.fetch("llm_call_id"), response.fetch("llm_call_id"))
    end
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
            "relative_path" => "_workspace/Projects/workspace-cli",
            "materialization_status" => "materialized_planned",
            "initial_implementation_status" => "planned",
            "runnable" => false,
            "validation_status" => "skipped"
          }
        }
      },
      user_text: "/done",
      trace_id: "trc-test"
    )

    assert_match "workspace-cli (77)", message
    assert_match "_workspace/Projects/workspace-cli", message
    assert_match "Materialization: materialized planned.", message
    assert_match "Initial implementation: planned.", message
    assert_match "Runnable: no.", message
    assert_match "Validation: skipped.", message
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

  def test_renders_guided_alignment_question_from_structured_intent
    renderer = Redwright::ProjectSetupPromptRenderer.new

    message = renderer.render(
      body: {
        "status" => "ok",
        "summary" => "Guided alignment advanced.",
        "data" => {
          "next_prompt_intent" => {
            "kind" => "guided_alignment_question",
            "question_key" => "operators",
            "metadata" => {
              "question_text" => "Who will use or operate this project?"
            }
          }
        }
      },
      user_text: "Optimize for fast reviews.",
      trace_id: "trc-test"
    )

    assert_match "Who will use or operate this project?", message
    assert_match "/cancel", message
  end

  def test_renders_repository_clarification_from_structured_intent
    renderer = Redwright::ProjectSetupPromptRenderer.new

    message = renderer.render(
      body: {
        "status" => "ok",
        "summary" => "Repository input requires clarification.",
        "data" => {
          "next_prompt_intent" => {
            "kind" => "repository_clarification_question",
            "metadata" => {
              "question_text" => "Repository input is ambiguous. Use URL, git@host:owner/repo, or owner/repo."
            }
          }
        }
      },
      user_text: "repo maybe",
      trace_id: "trc-test"
    )

    assert_match "Repository input is ambiguous.", message
    assert_match "Reply with the repository reference", message
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

  def test_falls_back_when_llm_renderer_returns_malformed_output
    renderer = Redwright::ProjectSetupPromptRenderer.new(llm_client: MalformedLlmClient.new, model: "example/model")

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
    refute_match "not json", message
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

  private

  def capture_stdout
    original = $stdout
    io = StringIO.new
    $stdout = io
    yield
    io.string
  ensure
    $stdout = original
  end

  def with_env(vars)
    backup = {}
    vars.each_key do |key|
      backup[key] = ENV.key?(key) ? ENV[key] : :__missing__
    end
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    backup.each do |key, value|
      if value == :__missing__
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end
end
