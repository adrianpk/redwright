require "test_helper"
require "tmpdir"

module AgentTicketExecution
  class PreviousInteractionStoreTest < ActiveSupport::TestCase
    test "stores and returns recent raw agent llm interaction records for a ticket session" do
      with_agent_ticket_execution_workspace do |fixture|
        Dir.mktmpdir("redwright-agent-previous-interactions-") do |dir|
          store = PreviousInteractionStore.new(root: dir)

          store.append(
            ticket: fixture.ticket,
            request: request_payload(agent_id: "agent-a"),
            request_payload: {"prompt" => "Implement done command"},
            response_payload: {"files" => ["main.go"]},
            outcome: "needs_retry",
            failure_summary: "go test failed",
            context_section_names: %w[ticket tests]
          )
          store.append(
            ticket: fixture.ticket,
            request: request_payload(agent_id: "agent-b"),
            request_payload: {"prompt" => "Different agent"},
            response_payload: {"message" => "ignored"}
          )

          records = store.recent(ticket: fixture.ticket, request: request_payload(agent_id: "agent-a"))

          assert_equal 1, records.length
          assert_equal "agent_ticket_execution", records.first.fetch("operation_kind")
          assert_equal "agent_llm_loop", records.first.fetch("source")
          assert_equal fixture.ticket.id, records.first.fetch("ticket_id")
          assert_equal "go test failed", records.first.fetch("failure_summary")
          assert_equal %w[ticket tests], records.first.fetch("context_section_names")
        end
      end
    end

    private

    def request_payload(agent_id:)
      {
        "ticket_id" => "ticket-test",
        "session_id" => "run-1",
        "agent_id" => agent_id,
        "actor_identifier" => "human-operator"
      }
    end
  end
end
