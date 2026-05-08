.PHONY: agent-ticket-scenario-reset llm-trace

agent-ticket-scenario-reset:
	cd apps/web && bin/rails runner ../../scripts/testing/prepare_agent_ticket_scenario.rb

llm-trace:
	./scripts/trace-llm.sh
