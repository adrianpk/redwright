module ProjectInitialization
  class Orchestrator
    def initialize(command:)
      @command = command
    end

    def call
      return Result.invalid_command(@command.errors) unless @command.valid?

      # Slice 1 intentionally stops at repository resolution boundary.
      # Later slices implement ambiguity/cancellation and side effects.
      Result.repository_resolution_required(@command)
    end
  end
end
