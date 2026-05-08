require Rails.root.join("..", "..", "lib", "redwright", "primitive_executor").expand_path.to_s

module AgentTicketExecution
  class WorkspaceBoundary
    DEFAULT_BRANCH_PREFIX = "agent-ticket".freeze

    Result = Struct.new(
      :ok,
      :ticket,
      :project,
      :workspace_path,
      :branch_name,
      :primitive_executor,
      :code,
      :message,
      keyword_init: true
    ) do
      def ok?
        ok == true
      end

      def context
        {
          "workspace_path" => workspace_path,
          "branch_name" => branch_name,
          "project_id" => project&.id,
          "ticket_id" => ticket&.id
        }
      end
    end

    def initialize(allowed_projects_root: nil)
      @allowed_projects_root = normalize_path(allowed_projects_root)
    end

    def resolve(ticket:, branch_name: nil)
      project = ticket&.project
      return failure("project_missing", "ticket project is missing", ticket: ticket) unless project

      workspace_path = normalize_path(project.root_path)
      return failure("workspace_missing", "project workspace path is missing", ticket: ticket, project: project) unless workspace_path
      return failure("workspace_not_found", "project workspace path does not exist", ticket: ticket, project: project, workspace_path: workspace_path) unless File.directory?(workspace_path)
      return failure("workspace_outside_allowed_root", "project workspace is outside the allowed projects root", ticket: ticket, project: project, workspace_path: workspace_path) unless inside_allowed_root?(workspace_path)

      Result.new(
        ok: true,
        ticket: ticket,
        project: project,
        workspace_path: workspace_path,
        branch_name: branch_name.presence || default_branch_name(ticket),
        primitive_executor: Redwright::PrimitiveExecutor.new(
          allowed_projects_root: workspace_path,
          enforce_mutating_projects_root: true
        )
      )
    end

    private

    attr_reader :allowed_projects_root

    def inside_allowed_root?(workspace_path)
      return true unless allowed_projects_root
      return true if workspace_path == allowed_projects_root

      workspace_path.start_with?("#{allowed_projects_root}/")
    end

    def default_branch_name(ticket)
      suffix = ticket.display_key.parameterize.presence || ticket.id
      "#{DEFAULT_BRANCH_PREFIX}-#{suffix}"
    end

    def normalize_path(path)
      value = path.to_s.strip
      return nil if value.empty?

      File.expand_path(value)
    end

    def failure(code, message, ticket: nil, project: nil, workspace_path: nil)
      Result.new(
        ok: false,
        ticket: ticket,
        project: project,
        workspace_path: workspace_path,
        branch_name: nil,
        primitive_executor: nil,
        code: code,
        message: message
      )
    end
  end
end
