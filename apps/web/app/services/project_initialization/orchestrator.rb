module ProjectInitialization
  class Orchestrator
    def initialize(command:, repository_resolver: RepositoryResolver)
      @command = command
      @repository_resolver = repository_resolver
    end

    def call
      return Result.invalid_command(@command.errors) unless @command.valid?

      resolution = @repository_resolver.new(input: @command.repository_input).call
      return Result.initialization_cancelled(@command) if resolution[:status] == :cancelled
      return Result.repository_resolution_ambiguous(@command, resolution[:clarification]) if resolution[:status] == :ambiguous

      Result.repository_resolved(@command, resolution[:repository])
    end
  end
end
