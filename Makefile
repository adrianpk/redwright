.PHONY: agent-ticket-scenario-reset agent-ticket-scenario-ready agent-ticket-scenario-inspect llm-trace

agent-ticket-scenario-reset:
	cd apps/web && bin/rails runner ../../scripts/testing/prepare_agent_ticket_scenario.rb

agent-ticket-scenario-ready:
	./scripts/testing/ready_agent_ticket_scenario.sh

agent-ticket-scenario-inspect:
	./scripts/testing/inspect_agent_ticket_scenario.sh

llm-trace:
	./scripts/trace-llm.sh
