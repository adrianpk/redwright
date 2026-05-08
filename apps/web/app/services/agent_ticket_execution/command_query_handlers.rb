require "pathname"

require Rails.root.join("..", "..", "lib", "redwright", "app_config").expand_path.to_s
require Rails.root.join("..", "..", "lib", "redwright", "llm", "request_engine").expand_path.to_s
require Rails.root.join("..", "..", "lib", "redwright", "llm", "trace_recorder").expand_path.to_s
require Rails.root.join("..", "..", "lib", "redwright", "llm_client_registry").expand_path.to_s
require Rails.root.join("..", "..", "lib", "redwright", "model_resolver").expand_path.to_s

module AgentTicketExecution
  class CommandQueryHandlers
    COMMAND_NAME = RequestBuilder::COMMAND_NAME

    def self.register(dispatcher)
      new(**default_dependencies).register(dispatcher)
    end

    def self.default_dependencies
      return {} if Rails.env.test?

      workspace_root = Rails.root.join("..", "..", "_workspace").expand_path.to_s
      context_composer = ContextComposer.new
      {
        executor: default_executor(context_composer: context_composer),
        workspace_boundary: WorkspaceBoundary.new(allowed_projects_root: workspace_root),
        context_composer: context_composer
      }
    end

    def self.default_executor(context_composer:)
      ValidationExecutor.new(
        validation_loop: ValidationLoop.new(
          context_composer: context_composer,
          llm_requester: default_llm_requester,
          previous_interaction_store: PreviousInteractionStore.new
        ),
        git_finalizer: GitFinalizer.new
      )
    end

    def self.default_llm_requester
      llm_context = default_llm_context
      LlmRequester.new(
        request_engine: llm_context.fetch(:request_engine),
        model: llm_context.fetch(:model),
        provider: llm_context.fetch(:provider),
        trace_recorder: Redwright::LLM::TraceRecorder.new
      )
    end

    def self.default_llm_context
      return unavailable_llm_context unless defined?(Redwright::AppConfigLoader)

      repo_root = Rails.root.join("../..").expand_path.to_s
      config = Redwright::AppConfigLoader.new(mode: :dev, pwd: repo_root).load(ingress: "none")
      Redwright::Trace.configure(tracing: normalized_tracing(config, repo_root: repo_root)) if defined?(Redwright::Trace)
      resolved_model = Redwright::ModelResolver.new(config.models).resolve(LlmContract::MODEL_ROLE)
      llm_client = Redwright::LlmClientRegistry.new.client_for(resolved_model.provider)
      {
        request_engine: Redwright::LLM::RequestEngine.new(llm_client: llm_client),
        model: resolved_model.name,
        provider: resolved_model.provider
      }
    rescue StandardError
      unavailable_llm_context
    end

    def self.unavailable_llm_context
      {
        request_engine: Redwright::LLM::RequestEngine.new(llm_client: nil),
        model: ENV.fetch("REDWRIGHT_AGENT_TICKET_MODEL", "none"),
        provider: ENV.fetch("REDWRIGHT_AGENT_TICKET_PROVIDER", "none")
      }
    end

    def self.normalized_tracing(config, repo_root:)
      llm_file = config.tracing.llm_file
      return config.tracing unless llm_file && defined?(Redwright::TracingConfig) && defined?(Redwright::LlmFileTraceConfig)

      path = llm_file.path.to_s
      normalized_path = Pathname.new(path).absolute? ? path : File.expand_path(path, repo_root)
      Redwright::TracingConfig.new(
        llm_file: Redwright::LlmFileTraceConfig.new(
          enabled: llm_file.enabled,
          path: normalized_path,
          max_bytes: llm_file.max_bytes,
          keep_files: llm_file.keep_files,
          include_payloads: llm_file.include_payloads,
          include_system_prompt: llm_file.include_system_prompt,
          include_user_text: llm_file.include_user_text,
          include_raw_output: llm_file.include_raw_output
        )
      )
    end

    def initialize(executor: nil, selection_policy: nil, workspace_boundary: nil, context_composer: nil, kanban_transitioner: nil, request_builder: nil, runner: nil, response_presenter: nil)
      executor ||= AcceptedExecutor.new
      @request_builder = request_builder || RequestBuilder.new
      @runner = runner || Runner.new(
        executor: executor,
        selection_policy: selection_policy,
        workspace_boundary: workspace_boundary,
        context_composer: context_composer,
        kanban_transitioner: kanban_transitioner || KanbanTransitioner.new
      )
      @response_presenter = response_presenter || ResponsePresenter.new
    end

    def register(dispatcher)
      dispatcher.register_command(COMMAND_NAME, method(:execute_agent_ticket))
      dispatcher
    end

    def execute_agent_ticket(payload:, context:, request_id:)
      request = request_builder.build(payload: payload, context: context, request_id: request_id)
      return invalid_payload_result(request_id: request_id, message: request.fetch("error")) if request.key?("error")

      result = runner.call(request: request)
      return selection_error_result(result, request_id: request_id) if result.is_a?(TicketSelectionPolicy::Result) && !result.ok?
      return workspace_error_result(result, request_id: request_id) if result.is_a?(WorkspaceBoundary::Result) && !result.ok?

      response_presenter.present(result: result, request_id: request_id)
    end

    private

    attr_reader :request_builder, :runner, :response_presenter

    def invalid_payload_result(request_id:, message:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "invalid_payload",
        message: message
      )
    end

    def selection_error_result(selection, request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: selection.code,
        message: selection.message
      )
    end

    def workspace_error_result(workspace, request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: workspace.code,
        message: workspace.message
      )
    end
  end

  class AcceptedExecutor
    def call(request:, ticket:, workspace: nil, execution_context: nil)
      {
        "state" => "accepted",
        "acknowledgement" => {
          "status" => "accepted",
          "message" => "Agent ticket execution accepted.",
          "request_id" => request.fetch("request_id"),
          "ticket_id" => ticket&.id || request.fetch("ticket_id"),
          "ticket_ref" => ticket&.display_key || request.fetch("ticket_ref"),
          "ticket_key" => ticket&.ticket_key,
          "mode" => request.fetch("mode")
        },
        "terminal_outcome" => nil,
        "details" => {
          "async" => true,
          "executor" => "accepted_boundary",
          "workspace_path" => workspace&.workspace_path,
          "context_sections" => execution_context&.diagnostics&.fetch("section_names", nil)
        }
      }
    end
  end
end
