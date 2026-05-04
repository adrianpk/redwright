require "test_helper"

module ProjectSetup
  class MaterializationPipelineTest < ActiveSupport::TestCase
    test "executes named steps in order and returns structured step results" do
      session = ProjectSetupSession.create!(
        actor_identifier: "human-1",
        request_id: "req-materialization-pipeline"
      )
      calls = []

      pipeline = MaterializationPipeline.new(
        session: session,
        operations: MaterializationPipeline::STEP_ORDER.each_with_object({}) do |step_name, ops|
          ops[step_name] = lambda { |outputs|
            calls << step_name
            {"#{step_name}_done".to_sym => true}.merge(outputs.empty? ? {} : {})
          }
        end
      )

      result = pipeline.call

      assert_equal MaterializationPipeline::STEP_ORDER, calls
      assert_equal MaterializationPipeline::STEP_ORDER.length, result.step_results.length
      assert_equal "create_project", result.step_results.first.fetch("name")
      assert_equal "ok", result.step_results.first.fetch("status")
      assert_equal true, result.step_results.first.dig("data", "create_project_done")
      assert_equal session.id, result.step_results.first.dig("reconciliation", "session_id")
      assert_equal true, result.outputs.fetch(:finalize_session_metadata_done)
    end
  end
end
