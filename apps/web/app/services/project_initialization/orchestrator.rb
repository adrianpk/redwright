module ProjectInitialization
  class Orchestrator
    def initialize(command:, repository_resolver: RepositoryResolver)
      @command = command
      @repository_resolver = repository_resolver
    end

    def call
      return Result.invalid_command(@command.errors) unless @command.valid?
      unless @command.ready_for_repository_resolution?
        return Result.setup_context_required(
          @command,
          missing_slots: @command.missing_context_slots,
          next_prompt_intent: next_prompt_intent
        )
      end

      resolution = @repository_resolver.new(input: @command.repository_input).call
      return Result.initialization_cancelled(@command) if resolution[:status] == :cancelled
      return Result.repository_resolution_ambiguous(@command, resolution[:clarification]) if resolution[:status] == :ambiguous

      Result.repository_resolved(@command, resolution[:repository])
    end

    private

    def next_prompt_intent
      slot = if @command.project_name.empty?
               "project_name"
             elsif @command.description.empty?
               "description"
             else
               "project_type"
             end

      {
        kind: "setup_slot_question",
        slot: slot,
        locale: "auto",
        llm_required: true
      }
    end
  end
end
