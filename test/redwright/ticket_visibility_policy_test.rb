# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/ticket_visibility_policy"

class TicketVisibilityPolicyTest < Minitest::Test
  def test_deny_label_takes_precedence
    policy = Redwright::TicketVisibilityPolicy.new
    ticket = { "assignee" => "agent_coder", "labels" => ["visible:agent", "human-only"] }

    result = policy.evaluate(ticket: ticket, actor_id: "agent_coder", allow_labels: ["visible:agent"], deny_labels: ["human-only"])

    assert_equal(false, result.allowed)
    assert_equal("deny_label", result.reason_code)
  end

  def test_assignee_grants_visibility
    policy = Redwright::TicketVisibilityPolicy.new
    ticket = { "assignee" => "agent_coder", "labels" => [] }

    result = policy.evaluate(ticket: ticket, actor_id: "agent_coder", allow_labels: [], deny_labels: [])

    assert_equal(true, result.allowed)
    assert_equal("assignee_match", result.reason_code)
  end

  def test_allow_label_grants_visibility
    policy = Redwright::TicketVisibilityPolicy.new
    ticket = { "assignee" => nil, "labels" => ["visible:agent"] }

    result = policy.evaluate(ticket: ticket, actor_id: "agent_reviewer", allow_labels: ["visible:agent"], deny_labels: [])

    assert_equal(true, result.allowed)
    assert_equal("allow_label", result.reason_code)
  end

  def test_default_deny_when_no_rule_matches
    policy = Redwright::TicketVisibilityPolicy.new
    ticket = { "assignee" => nil, "labels" => ["internal"] }

    result = policy.evaluate(ticket: ticket, actor_id: "agent_reviewer", allow_labels: ["visible:agent"], deny_labels: [])

    assert_equal(false, result.allowed)
    assert_equal("default_deny", result.reason_code)
  end
end
