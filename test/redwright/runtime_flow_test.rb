# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"
require "redwright/action_execution_store"
require "redwright/alignment_store"
require "redwright/psam_store"
require "redwright/plan_spec_store"
require "redwright/runtime_flow"
require "redwright/primitive_executor"
require "redwright/trace"
require "redwright/alignment_question_engine"

class RuntimeFlowTest < Minitest::Test
  FlakyTaskStore = Struct.new(:real_store, :failures_left) do
    def create(**kwargs)
      if failures_left.positive?
        self.failures_left -= 1
        raise StandardError, "transient task store failure"
      end

      real_store.create(**kwargs)
    end
  end

  class RecordingSkillDispatcher
    attr_reader :before_action_calls, :after_action_calls

    def initialize
      @before_action_calls = 0
      @after_action_calls = 0
    end

    def before_action(action:, context:)
      @before_action_calls += 1
      action
    end

    def after_action(action:, result:, context:)
      @after_action_calls += 1
      result
    end
  end

  class ScriptedAlignmentEngine
    def initialize(turns)
      @turns = turns
    end

    def next_turn(model:, objective:, prior_turns:)
      @turns.shift || Redwright::AlignmentQuestionEngine::Turn.new(
        status: "ready",
        question: "",
        recommendation: "done",
        rationale: "done",
        decision_node: "done",
        tags: ["done"],
        completion_status: "done",
        source: "test",
        finish_reason: "stop"
      )
    end
  end

  def test_process_creates_workstream_and_task_for_non_plan_intent_with_confirmation
    Dir.mktmpdir("redwright-flow-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)

        project = project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store
        )

        result = flow.process(
          project_ref: "rw",
          intent: "change",
          message: "implement init",
          confirm_new_workstream: true
        )

        assert_equal(project.id, result.project.id)
        assert_equal(project.id, result.workstream.project_id)
        assert_equal("change", result.workstream.intent)
        assert_equal("executing", result.workstream.state)
        assert_equal(result.workstream.id, result.task.workstream_id)
        assert_equal("implement init", result.task.description)
      end
    end
  end

  def test_process_with_existing_workstream_reuses_it
    Dir.mktmpdir("redwright-flow-reuse-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)

        project = project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        ws = ws_store.create(project_id: project.id, intent: "investigate", state: "executing")

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store
        )
        result = flow.process(project_ref: "rw", intent: "change", message: "continue analysis", workstream_id: ws.id)

        assert_equal(ws.id, result.workstream.id)
        assert_equal("continue analysis", result.task.description)
        assert_equal(1, ws_store.list(project_id: project.id).size)
      end
    end
  end

  def test_non_plan_without_confirmation_fails_when_no_workstream_exists
    Dir.mktmpdir("redwright-flow-confirmation-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)
        spec_store = Redwright::PlanSpecStore.new(base_dir: dir)

        project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store,
          plan_spec_store: spec_store
        )

        err = assert_raises(ArgumentError) do
          flow.process(project_ref: "rw", intent: "change", message: "do something")
        end
        assert_match("requires confirmation", err.message)
      end
    end
  end

  def test_plan_intent_enforces_one_question_at_a_time_until_ready
    Dir.mktmpdir("redwright-flow-plan-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)
        spec_store = Redwright::PlanSpecStore.new(base_dir: dir)

        project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store,
          psam_store: Redwright::PsamStore.new(bootstrap.db_path),
          alignment_question_engine: ScriptedAlignmentEngine.new([
            Redwright::AlignmentQuestionEngine::Turn.new(
              status: "continue",
              question: "Q1?",
              recommendation: "R1",
              rationale: "Why 1",
              decision_node: "n1",
              tags: ["scope"],
              completion_status: "open",
              source: "test",
              finish_reason: "stop"
            ),
            Redwright::AlignmentQuestionEngine::Turn.new(
              status: "continue",
              question: "Q2?",
              recommendation: "R2",
              rationale: "Why 2",
              decision_node: "n2",
              tags: ["io"],
              completion_status: "open",
              source: "test",
              finish_reason: "stop"
            ),
            Redwright::AlignmentQuestionEngine::Turn.new(
              status: "continue",
              question: "Q3?",
              recommendation: "R3",
              rationale: "Why 3",
              decision_node: "n3",
              tags: ["arch"],
              completion_status: "open",
              source: "test",
              finish_reason: "stop"
            ),
            Redwright::AlignmentQuestionEngine::Turn.new(
              status: "ready",
              question: "",
              recommendation: "Done",
              rationale: "Sufficient",
              decision_node: "ready",
              tags: ["ready"],
              completion_status: "done",
              source: "test",
              finish_reason: "stop"
            )
          ]),
          plan_spec_store: spec_store
        )

        first = flow.process(project_ref: "rw", intent: "plan", message: "need planning")
        assert_equal("waiting_user", first.workstream.state)
        refute_nil(first.alignment.pending_question)
        assert_equal(0, first.alignment.step_index)
        assert_equal(1, first.alignment.unresolved_count)

        second = flow.process(project_ref: "rw", intent: "plan", workstream_id: first.workstream.id, message: "use case is CLI runtime")
        assert_equal("waiting_user", second.workstream.state)
        assert_equal(1, second.alignment.step_index)
        refute_nil(second.alignment.pending_question)

        third = flow.process(project_ref: "rw", intent: "plan", workstream_id: first.workstream.id, message: "input text output actions failures include db errors")
        assert_equal("waiting_user", third.workstream.state)
        assert_equal(2, third.alignment.step_index)
        refute_nil(third.alignment.pending_question)

        fourth = flow.process(project_ref: "rw", intent: "plan", workstream_id: first.workstream.id, message: "components are cli stores and flow")
        assert_equal("ready", fourth.workstream.state)
        assert_equal(3, fourth.alignment.step_index)
        assert_nil(fourth.alignment.pending_question)
        assert_equal(0, fourth.alignment.unresolved_count)
        assert(fourth.alignment.decisions_stable)
        refute_nil(fourth.functional_spec_path)
        refute_nil(fourth.technical_spec_path)
        assert(File.file?(fourth.functional_spec_path))
        assert(File.file?(fourth.technical_spec_path))
      end
    end
  end

  def test_resume_intent_defaults_to_latest_workstream_for_project
    Dir.mktmpdir("redwright-flow-resume-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)
        spec_store = Redwright::PlanSpecStore.new(base_dir: dir)

        project = project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        older = ws_store.create(project_id: project.id, intent: "change", state: "executing")
        _newer = ws_store.create(project_id: project.id, intent: "investigate", state: "ready")

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store,
          plan_spec_store: spec_store
        )

        result = flow.process(project_ref: "rw", intent: "resume", message: "continue from latest")
        assert_equal("investigate", result.workstream.intent)
        refute_equal(older.id, result.workstream.id)
        assert_equal(result.workstream.id, result.task.workstream_id)
      end
    end
  end

  def test_resume_intent_without_existing_workstream_raises
    Dir.mktmpdir("redwright-flow-resume-empty-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)
        spec_store = Redwright::PlanSpecStore.new(base_dir: dir)

        project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store,
          plan_spec_store: spec_store
        )

        err = assert_raises(ArgumentError) { flow.process(project_ref: "rw", intent: "resume", message: "resume now") }
        assert_match("no resumable workstream found", err.message)
      end
    end
  end

  def test_blocked_retry_attempts_retries_then_succeeds
    Dir.mktmpdir("redwright-flow-retry-success-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        real_task_store = Redwright::TaskStore.new(bootstrap.db_path)
        flaky_task_store = FlakyTaskStore.new(real_task_store, 1)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)
        spec_store = Redwright::PlanSpecStore.new(base_dir: dir)

        project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: flaky_task_store,
          alignment_store: alignment_store,
          plan_spec_store: spec_store
        )

        result = flow.process(
          project_ref: "rw",
          intent: "change",
          message: "retry once",
          confirm_new_workstream: true,
          blocked_retry_attempts: 2
        )
        assert_equal("retry once", result.task.description)
      end
    end
  end

  def test_blocked_retry_attempts_exhaustion_raises_runtime_error
    Dir.mktmpdir("redwright-flow-retry-fail-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        real_task_store = Redwright::TaskStore.new(bootstrap.db_path)
        flaky_task_store = FlakyTaskStore.new(real_task_store, 3)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)
        spec_store = Redwright::PlanSpecStore.new(base_dir: dir)

        project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: flaky_task_store,
          alignment_store: alignment_store,
          plan_spec_store: spec_store
        )

        err = assert_raises(RuntimeError) do
          flow.process(
            project_ref: "rw",
            intent: "change",
            message: "retry fail",
            confirm_new_workstream: true,
            blocked_retry_attempts: 2
          )
        end
        assert_match("blocked after 2 attempt", err.message)
      end
    end
  end

  def test_process_executes_actions_and_persists_action_results
    Dir.mktmpdir("redwright-flow-actions-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        action_store = Redwright::ActionExecutionStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)

        project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store,
          primitive_executor: Redwright::PrimitiveExecutor.new,
          action_execution_store: action_store
        )

        result = flow.process(
          project_ref: "rw",
          intent: "change",
          message: "create smoke file",
          confirm_new_workstream: true,
          actions: [
            {
              "id" => "a1",
              "type" => "write_file",
              "args" => { "path" => "README.slice3.txt", "content" => "slice-3" },
              "requires_confirmation" => false,
              "timeout_ms" => 2_000,
              "on_failure" => "abort"
            },
            {
              "id" => "a2",
              "type" => "read_file",
              "args" => { "path" => "README.slice3.txt" },
              "requires_confirmation" => false,
              "timeout_ms" => 2_000,
              "on_failure" => "abort"
            }
          ]
        )

        assert_equal(2, result.action_results.size)
        assert_equal("ok", result.action_results[0].status)
        assert_equal("ok", result.action_results[1].status)
        assert_equal("slice-3", result.action_results[1].stdout)
        rows = action_store.list(task_id: result.task.id)
        assert_equal(2, rows.size)
        assert_equal("a1", rows[0].action_id)
        assert_equal("a2", rows[1].action_id)
      end
    end
  end

  def test_process_invokes_skill_dispatcher_action_hooks
    Dir.mktmpdir("redwright-flow-skill-hooks-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        action_store = Redwright::ActionExecutionStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)
        dispatcher = RecordingSkillDispatcher.new

        project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store,
          primitive_executor: Redwright::PrimitiveExecutor.new,
          action_execution_store: action_store,
          skill_dispatcher: dispatcher
        )

        flow.process(
          project_ref: "rw",
          intent: "change",
          message: "hook test",
          confirm_new_workstream: true,
          actions: [
            {
              "id" => "a1",
              "type" => "list_files",
              "args" => {},
              "requires_confirmation" => false,
              "timeout_ms" => 2_000,
              "on_failure" => "abort"
            }
          ]
        )

        assert_equal(1, dispatcher.before_action_calls)
        assert_equal(1, dispatcher.after_action_calls)
      end
    end
  end

  def test_process_normalizes_macro_actions_before_execution
    Dir.mktmpdir("redwright-flow-macro-actions-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        action_store = Redwright::ActionExecutionStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)

        project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store,
          primitive_executor: Redwright::PrimitiveExecutor.new,
          action_execution_store: action_store
        )

        result = flow.process(
          project_ref: "rw",
          intent: "change",
          message: "macro action smoke",
          confirm_new_workstream: true,
          actions: [
            {
              "id" => "files",
              "type" => "write_files",
              "args" => {
                "files" => {
                  "demo/a.txt" => "A",
                  "demo/b.txt" => "B"
                }
              },
              "requires_confirmation" => false,
              "timeout_ms" => 2_000,
              "on_failure" => "abort"
            },
            {
              "id" => "verify",
              "type" => "run_command",
              "args" => { "cmd" => "test -f demo/a.txt && test -f demo/b.txt && echo ok" },
              "requires_confirmation" => false,
              "timeout_ms" => 2_000,
              "on_failure" => "abort"
            }
          ]
        )

        assert_equal(3, result.action_results.size)
        assert_equal("files.1", result.action_results[0].action_id)
        assert_equal("write_file", result.action_results[0].action_type)
        assert_equal("files.2", result.action_results[1].action_id)
        assert_equal("write_file", result.action_results[1].action_type)
        assert_equal("verify", result.action_results[2].action_id)
        assert_equal("run", result.action_results[2].action_type)
        assert_equal("ok\n", result.action_results[2].stdout)
      end
    end
  end

  def test_process_preserves_existing_turn_trace_id_for_task_and_actions
    Dir.mktmpdir("redwright-flow-trace-correlation-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        action_store = Redwright::ActionExecutionStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)

        project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store,
          primitive_executor: Redwright::PrimitiveExecutor.new,
          action_execution_store: action_store
        )

        result = nil
        Redwright::Trace.with_trace_id("trc-unified-1") do
          result = flow.process(
            project_ref: "rw",
            intent: "change",
            message: "trace correlation",
            confirm_new_workstream: true,
            actions: [
              {
                "id" => "a1",
                "type" => "list_files",
                "args" => {},
                "requires_confirmation" => false,
                "timeout_ms" => 2_000,
                "on_failure" => "abort"
              }
            ]
          )
        end

        task = task_store.get(result.task.id)
        assert_equal("trc-unified-1", task.trace_id)
        rows = action_store.list(task_id: result.task.id)
        assert_equal(1, rows.size)
        assert_equal("trc-unified-1", rows.first.trace_id)
      end
    end
  end

  def test_plan_transition_validation_rejects_ready_to_waiting_user
    Dir.mktmpdir("redwright-flow-plan-transition-guard-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)
        spec_store = Redwright::PlanSpecStore.new(base_dir: dir)

        project = project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        workstream = ws_store.create(project_id: project.id, intent: "plan", state: "ready")
        alignment_store.ensure_session(workstream.id)

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store,
          plan_spec_store: spec_store
        )

        err = assert_raises(ArgumentError) do
          flow.process(project_ref: "rw", intent: "plan", workstream_id: workstream.id, message: "continue")
        end
        assert_match("invalid_alignment_transition", err.message)
      end
    end
  end
end
