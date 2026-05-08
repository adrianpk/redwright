require "pathname"

require Rails.root.join("..", "..", "lib", "redwright", "app_config").expand_path.to_s
require Rails.root.join("..", "..", "lib", "redwright", "llm", "request_engine").expand_path.to_s
require Rails.root.join("..", "..", "lib", "redwright", "llm", "trace_recorder").expand_path.to_s
require Rails.root.join("..", "..", "lib", "redwright", "llm_client_registry").expand_path.to_s
require Rails.root.join("..", "..", "lib", "redwright", "model_resolver").expand_path.to_s

module AgentTicketExecution
  class CommandQueryHandlers
    include CommandQuery::PayloadReader

    COMMAND_NAME = "ExecuteAgentTicket".freeze
    MODES = %w[targeted pickup].freeze

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

    def initialize(executor: nil, selection_policy: nil, workspace_boundary: nil, context_composer: nil, kanban_transitioner: nil)
      @executor = executor || AcceptedExecutor.new
      @selection_policy = selection_policy
      @workspace_boundary = workspace_boundary
      @context_composer = context_composer
      @kanban_transitioner = kanban_transitioner || KanbanTransitioner.new
    end

    def register(dispatcher)
      dispatcher.register_command(COMMAND_NAME, method(:execute_agent_ticket))
      dispatcher
    end

    def execute_agent_ticket(payload:, context:, request_id:)
      request = build_request(payload: payload, context: context, request_id: request_id)
      return invalid_payload_result(request_id: request_id, message: request.fetch("error")) if request.key?("error")

      board = request.fetch("board_id").present? ? Board.find_by(id: request.fetch("board_id")) : nil
      selection = select_ticket(request: request, board: board)
      return selection_error_result(selection, request_id: request_id) unless selection.ok?

      ticket = selection.ticket
      workspace = resolve_workspace(request: request, ticket: ticket)
      return workspace_error_result(workspace, request_id: request_id) if workspace && !workspace.ok?

      start_transition = kanban_transitioner.mark_started(ticket: ticket)
      execution_context = compose_execution_context(request: request, ticket: ticket, workspace: workspace)
      execution = normalize_execution(
        executor.call(
          request: request,
          ticket: ticket,
          workspace: workspace,
          execution_context: execution_context
        )
      )
      terminal_transition = kanban_transitioner.apply_terminal_outcome(ticket: ticket, execution: execution)
      execution.fetch("details")["kanban"] = {
        "start" => start_transition.to_h,
        "terminal" => terminal_transition.to_h
      }
      CommandQuery::Result.ok(
        request_id: request_id,
        data: execution_data(
          request: request,
          ticket: ticket,
          board: board,
          workspace: workspace,
          execution_context: execution_context,
          execution: execution
        ),
        effects: execution_effects(request: request, ticket: ticket, board: board, execution: execution)
      )
    end

    private

    attr_reader :executor
    attr_reader :selection_policy
    attr_reader :workspace_boundary
    attr_reader :context_composer
    attr_reader :kanban_transitioner

    def build_request(payload:, context:, request_id:)
      ticket_ref = value_from(payload, "ticket_ref", "ticket_id").presence
      mode = value_from(payload, "mode").presence || (ticket_ref.present? ? "targeted" : "pickup")
      mode = mode.to_s
      return {"error" => "mode must be one of: #{MODES.join(", ")}"} unless MODES.include?(mode)
      return {"error" => "ticket_ref is required for targeted execution"} if mode == "targeted" && ticket_ref.blank?
      return {"error" => "project_id or board_id is required for pickup execution"} if mode == "pickup" && value_from(payload, "project_id", "board_id").blank?

      {
        "command" => COMMAND_NAME,
        "request_id" => request_id.to_s,
        "mode" => mode,
        "ticket_ref" => ticket_ref.to_s.presence,
        "ticket_id" => ticket_ref.to_s.match?(/\A\d+\z/) ? ticket_ref.to_i : nil,
        "project_id" => value_from(payload, "project_id")&.to_i,
        "board_id" => value_from(payload, "board_id")&.to_i,
        "assignee" => value_from(payload, "assignee").to_s.presence,
        "admin_assignee" => value_from(payload, "admin_assignee").to_s.presence,
        "branch_name" => value_from(payload, "branch_name").to_s.presence,
        "session_id" => value_from(payload, "session_id").to_s.presence,
        "agent_id" => value_from(payload, "agent_id").to_s.presence,
        "actor_identifier" => actor_identifier_from(context),
        "source_channel" => value_from(context, "source_channel").to_s.presence || "unknown",
        "loop" => {
          "enabled" => truthy?(value_from(payload, "loop")),
          "max_tickets" => integer_value(value_from(payload, "max_tickets"), default: 1)
        }
      }
    end

    def select_ticket(request:, board:)
      policy = selection_policy_for(request)
      if request.fetch("mode") == "targeted"
        return policy.select_targeted(ticket: Ticket.resolve_ref(request.fetch("ticket_ref")))
      end

      policy.pick(
        board: board,
        project_id: request.fetch("project_id"),
        assignee: request.fetch("assignee")
      )
    end

    def selection_policy_for(request)
      return selection_policy if selection_policy

      TicketSelectionPolicy.new(admin_assignee: request.fetch("admin_assignee"))
    end

    def resolve_workspace(request:, ticket:)
      boundary = workspace_boundary
      return nil unless boundary

      boundary.resolve(ticket: ticket, branch_name: value_from(request, "branch_name"))
    end

    def compose_execution_context(request:, ticket:, workspace:)
      composer = context_composer
      return nil unless composer

      composer.compose(ticket: ticket, request: request, workspace: workspace)
    end

    def normalize_execution(raw)
      execution = raw.is_a?(Hash) ? raw : {}
      state = execution.fetch("state", "accepted").to_s

      {
        "state" => state,
        "acknowledgement" => execution.fetch("acknowledgement", acknowledgement_payload(state: state)),
        "terminal_outcome" => execution["terminal_outcome"],
        "details" => execution.fetch("details", {})
      }
    end

    def execution_data(request:, ticket:, board:, workspace:, execution_context:, execution:)
      {
        "summary" => summary_for(execution),
        "execution" => {
          "command" => COMMAND_NAME,
          "mode" => request.fetch("mode"),
          "state" => execution.fetch("state"),
          "ticket_id" => ticket&.id || request.fetch("ticket_id"),
          "ticket_ref" => ticket&.display_key || request.fetch("ticket_ref"),
          "human_key" => ticket&.human_key,
          "project_id" => ticket&.project_id || board&.project_id || request.fetch("project_id"),
          "board_id" => ticket&.board_id || board&.id || request.fetch("board_id"),
          "assignee" => request.fetch("assignee"),
          "workspace" => workspace&.context,
          "context" => execution_context&.diagnostics,
          "acknowledgement" => execution.fetch("acknowledgement"),
          "terminal_outcome" => execution.fetch("terminal_outcome"),
          "details" => execution.fetch("details")
        }
      }
    end

    def execution_effects(request:, ticket:, board:, execution:)
      [
        {
          "type" => "agent_ticket_execution_#{execution.fetch("state")}",
          "mode" => request.fetch("mode"),
          "ticket_id" => ticket&.id || request.fetch("ticket_id"),
          "ticket_ref" => ticket&.display_key || request.fetch("ticket_ref"),
          "human_key" => ticket&.human_key,
          "project_id" => ticket&.project_id || board&.project_id || request.fetch("project_id"),
          "board_id" => ticket&.board_id || board&.id || request.fetch("board_id")
        }
      ]
    end

    def summary_for(execution)
      return "Agent ticket execution completed." if execution.fetch("terminal_outcome").present?

      "Agent ticket execution accepted."
    end

    def acknowledgement_payload(state:)
      {
        "status" => state,
        "message" => "Agent ticket execution accepted."
      }
    end

    def truthy?(value)
      value == true || value.to_s == "true" || value.to_s == "1"
    end

    def integer_value(value, default:)
      Integer(value.presence || default)
    rescue ArgumentError, TypeError
      default
    end

    def actor_identifier_from(context)
      value_from(context, "actor_identifier").to_s.presence || "unknown"
    end

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
          "human_key" => ticket&.human_key,
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
