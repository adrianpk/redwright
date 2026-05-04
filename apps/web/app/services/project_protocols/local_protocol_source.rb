module ProjectProtocols
  class LocalProtocolSource
    PROTOCOL_FILES = [
      ["agents_root", "AGENTS.md", "AGENTS", "behavioral"],
      ["conventions", ".agents/CONVENTIONS.md", "Conventions", "behavioral"],
      ["architecture", ".agents/ARCHITECTURE.md", "Architecture", "stack"],
      ["documenting", ".agents/DOCUMENTING.md", "Documenting", "behavioral"],
      ["invariants", ".agents/INVARIANTS.md", "Invariants", "behavioral"],
      ["lifecycle", ".agents/LIFECYCLE.md", "Lifecycle", "behavioral"],
      ["linting", ".agents/LINTING.md", "Linting", "behavioral"],
      ["routing", ".agents/ROUTING.md", "Routing", "behavioral"],
      ["slices", ".agents/SLICES.md", "Slices", "behavioral"],
      ["versioning", ".agents/VERSIONING.md", "Versioning", "behavioral"],
      ["playbooks_index", ".agents/PLAYBOOKS.md", "Playbooks", "behavioral"],
      ["playbook_branching_and_pr_flow", ".agents/playbooks/branching-and-pr-flow.md", "Branching and PR Flow", "behavioral"],
      ["playbook_plan_driven_workflow", ".agents/playbooks/plan-driven-workflow.md", "Plan-Driven Workflow", "behavioral"],
      ["playbook_questionnaires", ".agents/playbooks/questionnaires.md", "Questionnaires", "behavioral"],
      ["playbook_release_alignment", ".agents/playbooks/release-alignment.md", "Release Alignment", "behavioral"],
      ["playbook_slice_delivery", ".agents/playbooks/slice-delivery.md", "Slice Delivery", "behavioral"],
      ["playbook_spec_draft_conversation_workflow", ".agents/playbooks/spec-draft-conversation-workflow.md", "Spec Draft Conversation Workflow", "behavioral"],
      ["playbook_ticket_workflow", ".agents/playbooks/ticket-workflow.md", "Ticket Workflow", "behavioral"]
    ].freeze

    def initialize(root: Rails.root.join("..", ".."))
      @root = root.expand_path
    end

    def documents
      PROTOCOL_FILES.each_with_index.map do |entry, position|
        key, path, title, layer = entry

        document_state(
          key: key,
          path: path,
          title: title,
          layer: layer,
          position: position,
          body: body_for(path)
        )
      end
    end

    def body_for(path)
      File.read(root.join(path)).strip
    end

    private

    attr_reader :root

    def document_state(key:, path:, title:, layer:, position:, body:)
      {
        "key" => key,
        "path" => path,
        "title" => title,
        "layer" => layer,
        "position" => position,
        "body" => body,
        "provenance" => {"source" => "local_protocol_source", "source_path" => path}
      }
    end
  end
end
