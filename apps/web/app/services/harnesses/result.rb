module Harnesses
  Result = Data.define(:bytes, :outcome, :value, :observed_provider, :observed_model, :usage, :usage_status, :diagnostics, :binding_digest) do
    def initialize(bytes:, outcome: :completed, value: nil, observed_provider: nil, observed_model: nil,
      usage: nil, usage_status: :unknown, diagnostics: {}, binding_digest: nil)
      super(bytes: bytes.dup.freeze, outcome: outcome, value: value,
        observed_provider: observed_provider, observed_model: observed_model, usage: usage, usage_status: usage_status,
        diagnostics: diagnostics, binding_digest: binding_digest)
    end
  end
end
