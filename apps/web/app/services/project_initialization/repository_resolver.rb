module ProjectInitialization
  class RepositoryResolver
    CANCELLATION_INPUTS = ["cancel", "abort", "/cancel", "/abort"].freeze

    attr_reader :input

    def initialize(input:)
      @input = input.to_s.strip
    end

    def call
      return {status: :cancelled} if cancellation_intent?

      if explicit_repository_url?
        return {
          status: :resolved,
          repository: {
            canonical: input,
            source: :explicit_url
          }
        }
      end

      if owner_repo_identifier?
        return {
          status: :resolved,
          repository: {
            canonical: "https://github.com/#{input}.git",
            source: :owner_repo
          }
        }
      end

      {
        status: :ambiguous,
        clarification: {
          reason: :unsupported_or_incomplete_repository_identifier,
          original_input: input,
          expected_formats: [
            "https://host/owner/repository(.git)",
            "git@host:owner/repository(.git)",
            "owner/repository"
          ]
        }
      }
    end

    private

    def cancellation_intent?
      CANCELLATION_INPUTS.include?(input.downcase)
    end

    def explicit_repository_url?
      input.match?(%r{\Ahttps?://\S+\z}) || input.match?(%r{\Agit@\S+:\S+\z})
    end

    def owner_repo_identifier?
      input.match?(%r{\A[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+\z})
    end
  end
end
