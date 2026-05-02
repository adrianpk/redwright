module ProjectInitialization
  class Executor
    def initialize(command:, resolved_repository:, lifecycle:)
      @command = command
      @resolved_repository = resolved_repository
      @lifecycle = lifecycle
    end

    def call
      context = {
        repository: nil,
        project: nil,
        workspace: nil
      }

      begin
        context[:repository] = @lifecycle.create_repository(
          command: @command,
          resolved_repository: @resolved_repository
        )
        context[:project] = @lifecycle.create_project(command: @command, repository: context[:repository])
        context[:workspace] = @lifecycle.create_workspace(command: @command, project: context[:project])

        Result.initialization_completed(@command, @resolved_repository, context)
      rescue StandardError => e
        reconciliation = @lifecycle.rollback(context: context, error: e)

        if reconciliation[:status] == :reconciled
          Result.initialization_failed(@command, @resolved_repository, context, e.message, reconciliation)
        else
          Result.initialization_incomplete(@command, @resolved_repository, context, e.message, reconciliation)
        end
      end
    end
  end
end
