# frozen_string_literal: true

module Redwright
  class TicketVisibilityPolicy
    Decision = Struct.new(:allowed, :reason_code, keyword_init: true)

    def evaluate(ticket:, actor_id:, allow_labels: [], deny_labels: [])
      labels = Array(ticket["labels"] || ticket[:labels]).map(&:to_s)
      assignee = (ticket["assignee"] || ticket[:assignee]).to_s
      actor = actor_id.to_s

      deny_match = labels & Array(deny_labels).map(&:to_s)
      return Decision.new(allowed: false, reason_code: "deny_label") unless deny_match.empty?

      return Decision.new(allowed: true, reason_code: "assignee_match") if !actor.empty? && assignee == actor

      allow_match = labels & Array(allow_labels).map(&:to_s)
      return Decision.new(allowed: true, reason_code: "allow_label") unless allow_match.empty?

      Decision.new(allowed: false, reason_code: "default_deny")
    end
  end
end
