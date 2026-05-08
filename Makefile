.PHONY: agent-ticket-scenario-reset

agent-ticket-scenario-reset:
	cd apps/web && bin/rails runner ../../scripts/testing/prepare_agent_ticket_scenario.rb
