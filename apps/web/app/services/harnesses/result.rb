module Harnesses
  Result = Data.define(:bytes, :outcome, :value, :observed_provider, :observed_model, :usage, :usage_status, :diagnostics) do
    def initialize(bytes:, outcome: :completed, value: nil, observed_provider: nil, observed_model: nil,
      usage: nil, usage_status: :unknown, diagnostics: {})
      super(bytes: bytes.dup.freeze, outcome: outcome, value: value,
        observed_provider: observed_provider, observed_model: observed_model, usage: usage, usage_status: usage_status, diagnostics: diagnostics)
    end
  end
end
