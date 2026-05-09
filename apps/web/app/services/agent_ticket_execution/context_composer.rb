require "json"

require Rails.root.join("..", "..", "lib", "redwright", "llm", "context_section").expand_path.to_s

module AgentTicketExecution
  class ContextComposer
    Context = Struct.new(:context_sections, :trace_metadata, :user_text, :diagnostics, keyword_init: true) do
      def llm_request_inputs
        {
          context_sections: context_sections,
          trace_metadata: trace_metadata,
          user_text: user_text
        }
      end
    end

    def initialize(
      previous_interaction_store: nil,
      previous_interaction_limit: PreviousInteractionStore::DEFAULT_LIMIT,
      section_providers: nil
    )
      @section_providers = section_providers || default_section_providers(
        previous_interaction_store: previous_interaction_store,
        previous_interaction_limit: previous_interaction_limit
      )
    end

    def compose(ticket:, request:, workspace:)
      project = ticket.project
      workspace_path = workspace&.workspace_path || project.root_path
      provider_context = ContextSectionProviders::Context.new(
        ticket: ticket,
        project: project,
        request: request,
        workspace_path: workspace_path
      )
      sections = section_providers.flat_map { |provider| provider.sections(provider_context) }

      Context.new(
        context_sections: sections,
        trace_metadata: trace_metadata(ticket, project, workspace_path, sections, request),
        user_text: JSON.generate(user_text_payload(ticket, request)),
        diagnostics: diagnostics(sections)
      )
    end

    private

    attr_reader :section_providers

    def default_section_providers(previous_interaction_store:, previous_interaction_limit:)
      [
        ContextSectionProviders::TicketProject.new,
        ContextSectionProviders::Repository.new,
        ContextSectionProviders::OperationalSetupSection.new,
        ContextSectionProviders::TreeSitterContext.new,
        ContextSectionProviders::Protocols.new,
        ContextSectionProviders::Documents.new,
        ContextSectionProviders::Quizzes.new,
        ContextSectionProviders::Dumps.new,
        ContextSectionProviders::DerivedLlmContext.new(
          store: previous_interaction_store,
          limit: previous_interaction_limit
        ),
        ContextSectionProviders::PreviousInteractions.new(
          store: previous_interaction_store,
          limit: previous_interaction_limit
        ),
        ContextSectionProviders::ValidationFeedback.new
      ]
    end

    def trace_metadata(ticket, project, workspace_path, sections, request)
      {
        trace_id: request["trace_id"],
        project_id: project.id,
        project_ref: project.repo_url,
        project_root: workspace_path,
        ticket_id: ticket.id,
        session_id: request["session_id"],
        source_channel: request["source_channel"],
        actor_identifier: request["actor_identifier"],
        context_summary: sections.map(&:to_h),
        context_bytes: sections.sum(&:bytes),
        context_sections: sections.map(&:name)
      }
    end

    def user_text_payload(ticket, request)
      payload = {
        "action" => "agent_ticket_execution",
        "ticket_id" => ticket.id,
        "ticket_title" => ticket.title,
        "ticket_description" => ticket.description,
        "mode" => request.fetch("mode"),
        "branch_name" => request["branch_name"]
      }
      payload["validation_feedback"] = request["validation_feedback"] if request["validation_feedback"].present?
      payload
    end

    def diagnostics(sections)
      {
        "section_names" => sections.map(&:name),
        "section_authorities" => sections.to_h { |section| [section.name, section.authority] },
        "context_bytes" => sections.sum(&:bytes)
      }
    end

  end
end
