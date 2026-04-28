# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/psam_store"

class PsamStoreTest < Minitest::Test
  def test_persists_psam_entities_and_retrieves_semantic_context
    Dir.mktmpdir("redwright-psam-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        psam = Redwright::PsamStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        ws = workstreams.create(project_id: project.id, intent: "plan")

        question_id = psam.create_question(
          workstream_id: ws.id,
          step_index: 1,
          question: "What is the target runtime contract?",
          recommendation: "Use one-question loop",
          rationale: "Reduces ambiguity",
          decision_node: "runtime.contract",
          completion_status: "open"
        )
        psam.create_answer(question_id: question_id, answer: "Bounded loop with explicit stop reasons")
        psam.add_tag(question_id: question_id, tag: "runtime")
        psam.add_tag(question_id: question_id, tag: "contract")
        psam.add_artifact_link(workstream_id: ws.id, question_id: question_id, artifact_kind: "spec", artifact_path: "ops/specs/spec.md")

        rows = psam.list_semantic_context(project_id: project.id, workstream_id: ws.id)
        assert_equal(1, rows.size)
        assert_equal("What is the target runtime contract?", rows.first[:question])
        assert_equal("Bounded loop with explicit stop reasons", rows.first[:answer])
        assert_equal(["contract", "runtime"], rows.first[:tags])
      end
    end
  end

  def test_enforces_relational_integrity_and_non_self_dependencies
    Dir.mktmpdir("redwright-psam-fk-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        psam = Redwright::PsamStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        ws = workstreams.create(project_id: project.id, intent: "plan")
        q1 = psam.create_question(workstream_id: ws.id, step_index: 1, question: "Q1?")
        q2 = psam.create_question(workstream_id: ws.id, step_index: 2, question: "Q2?")

        psam.add_dependency(question_id: q2, depends_on_question_id: q1)

        assert_raises(SQLite3::ConstraintException) do
          psam.create_answer(question_id: "missing-question", answer: "invalid")
        end

        assert_raises(SQLite3::ConstraintException) do
          psam.add_dependency(question_id: q1, depends_on_question_id: q1)
        end
      end
    end
  end
end
