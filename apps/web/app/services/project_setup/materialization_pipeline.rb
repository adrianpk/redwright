module ProjectSetup
  class MaterializationPipeline
    Result = Struct.new(:outputs, :step_results, keyword_init: true)

    STEP_ORDER = [
      :create_project,
      :ensure_default_board,
      :materialize_project_attributes,
      :write_setup_summary_document,
      :initialize_project_protocols,
      :initialize_runtime_containers,
      :ensure_starter_workflow_ticket,
      :ensure_runtime_containers_readiness_ticket,
      :materialize_local_workspace,
      :reconcile_starter_ticket_description,
      :reconcile_runtime_containers_readiness_ticket_description,
      :finalize_session_metadata
    ].freeze

    def initialize(session:, operations:)
      @session = session
      @operations = operations
    end

    def call
      outputs = {}
      step_results = []

      STEP_ORDER.each do |step_name|
        result, step_output = execute_step(step_name, outputs)
        step_results << result.to_h.merge("name" => step_name.to_s)
        outputs.merge!(step_output)
      end

      Result.new(outputs: outputs, step_results: step_results)
    end

    private

    attr_reader :session, :operations

    def execute_step(step_name, outputs)
      operation = operations.fetch(step_name)
      payload = operation.call(outputs)
      data = payload.is_a?(Hash) ? payload : {}
      result = HeavyInteractionSagas::StepResult.ok(
        data: data,
        reconciliation: {
          "session_id" => session.id,
          "step_name" => step_name.to_s
        }
      )
      [result, data]
    end
  end
end
