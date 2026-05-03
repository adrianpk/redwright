module ProjectInitialization
  class Orchestrator
    def initialize(command:, repository_resolver: RepositoryResolver)
      @command = command
      @repository_resolver = repository_resolver
    end

    def call
      return Result.invalid_command(@command.errors) unless @command.valid?
      return Result.setup_context_required(@command, missing_slots: @command.missing_context_slots, next_prompt: next_prompt) unless @command.ready_for_repository_resolution?

      resolution = @repository_resolver.new(input: @command.repository_input).call
      return Result.initialization_cancelled(@command) if resolution[:status] == :cancelled
      return Result.repository_resolution_ambiguous(@command, resolution[:clarification]) if resolution[:status] == :ambiguous

      Result.repository_resolved(@command, resolution[:repository])
    end

    private

    def next_prompt
      return "What should we call this project?" if @command.project_name.empty?
      return "What should this project do first?" if @command.description.empty?

      "Which stack or framework should this project use? Reply /skip if undecided."
    end
  end
end
