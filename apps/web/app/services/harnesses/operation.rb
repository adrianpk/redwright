module Harnesses
  class Operation
    MAX_ACTIVE_CALLS = 2
    Lease = Data.define(:operation_id, :owner_token, :binding, :resources)

    def initialize(store: BindingStore.new, clock: -> { Time.current })
      @store, @clock = store, clock
    end

    def start!(operation:)
      ApplicationRecord.transaction do
        record = HarnessOperation.find(operation.id)
        unless %w[prepared failed timed_out].include?(record.state)
          raise Error.new("This harness operation cannot start another call.", code: :conflict)
        end
        history = record.attempts
        if history.size >= (record.role == "ticket_proposal" ? 3 : 1)
          raise Error.new("The harness operation reached its existing attempt limit.", code: :attempt_limit)
        end
        if HarnessOperation.where(state: %w[running uncertain]).count >= MAX_ACTIVE_CALLS
          raise Error.new("Two harness calls are already active. Retry when capacity is released.", code: :capacity)
        end
        unless record.binding_valid?
          raise Error.new("Unsupported or damaged retained harness binding.", code: :invalid_binding)
        end
        resources = @store.read(record.private_run_ref)
        token = SecureRandom.hex(32)
        now = @clock.call
        history << {"number" => history.size + 1, "state" => "running", "owner_digest" => Digest::SHA256.hexdigest(token), "started_at" => now.iso8601(6)}
        record.update!(state: "running", attempts_json: CanonicalJson.dump(history), started_at: record.started_at || now, finished_at: nil)
        Lease.new(operation_id: record.id, owner_token: token.freeze, binding: record.binding, resources: resources)
      end
    end

    def finish!(lease:, outcome:, output_digest: nil, artifact_ref: nil, application_receipt: nil)
      unless (HarnessOperation::TERMINAL_STATES + ["uncertain"]).include?(outcome) &&
          (output_digest.nil? || /\A[0-9a-f]{64}\z/.match?(output_digest.to_s)) &&
          [artifact_ref, application_receipt].all? { |value| value.nil? || (value.is_a?(String) && value.bytesize.between?(1, 512)) }
        raise Error.new("Invalid harness call outcome.", code: :invalid_request)
      end
      completion = {"state" => outcome, "output_digest" => output_digest, "artifact_ref" => artifact_ref, "application_receipt" => application_receipt}
      digest = CanonicalJson.digest(completion)
      ApplicationRecord.transaction do
        record = HarnessOperation.find(lease.operation_id)
        history = record.attempts
        attempt = history.last
        unless attempt && ActiveSupport::SecurityUtils.secure_compare(attempt.fetch("owner_digest"), Digest::SHA256.hexdigest(lease.owner_token))
          raise Error.new("This call does not own the retained operation.", code: :conflict)
        end
        if !%w[running uncertain].include?(record.state)
          raise Error.new("This harness call was already finished differently.", code: :conflict) unless attempt["completion_digest"] == digest
          next record
        end
        now = @clock.call
        attempt.merge!(completion).merge!("completion_digest" => digest, "finished_at" => outcome == "uncertain" ? nil : now.iso8601(6))
        record.update!(state: outcome, attempts_json: CanonicalJson.dump(history), finished_at: outcome == "uncertain" ? nil : now)
        record
      end
    end
  end
end
