module ProjectInitialization
  class ActiveRecordLifecycle
    def create_repository(command:, resolved_repository:)
      {
        id: resolved_repository[:canonical],
        canonical: resolved_repository[:canonical],
        source: resolved_repository[:source],
        input: command.repository_input
      }
    end

    def create_project(command:, repository:)
      project = Project.create!(
        name: command.project_name,
        description: command.description.presence || "Project initialized from web entry flow",
        root_path: "/workspace/projects/#{command.directory_name}",
        repo_url: repository[:canonical],
        stack_slug: "ruby"
      )
      ProjectProtocols::InitializationService.new(project: project).call

      {id: project.id, model: project}
    end

    def create_workspace(command:, project:)
      {
        id: "workspace-#{project[:id]}",
        project_id: project[:id],
        directory_name: command.directory_name
      }
    end

    def rollback(context:, error:)
      context[:project]&.dig(:model)&.destroy!

      {
        status: :reconciled,
        cleaned: {
          repository: !context[:repository].nil?,
          project: !context[:project].nil?,
          workspace: !context[:workspace].nil?
        },
        error: error.message
      }
    rescue StandardError => rollback_error
      {
        status: :incomplete,
        cleaned: {
          repository: !context[:repository].nil?,
          project: false,
          workspace: false
        },
        error: "#{error.message}; rollback_error=#{rollback_error.message}"
      }
    end
  end
end
