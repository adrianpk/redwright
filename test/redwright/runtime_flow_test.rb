# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"
require "redwright/alignment_store"
require "redwright/plan_spec_store"
require "redwright/runtime_flow"

class RuntimeFlowTest < Minitest::Test
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
          plan_spec_store: spec_store
        )

        first = flow.process(project_ref: "rw", intent: "plan", message: "need planning")
        assert_equal("waiting_user", first.workstream.state)
        refute_nil(first.alignment.pending_question)
        assert_equal(0, first.alignment.step_index)
        assert_equal(3, first.alignment.unresolved_count)

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
end
