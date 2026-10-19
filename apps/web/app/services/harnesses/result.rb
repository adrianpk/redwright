module Harnesses
  Result = Data.define(:bytes, :outcome, :value, :observed_provider, :observed_model, :usage, :usage_status) do
    def initialize(bytes:, outcome: :completed, value: nil, observed_provider: nil, observed_model: nil,
      usage: nil, usage_status: :unknown)
      super(bytes: bytes.dup.freeze, outcome: outcome, value: value,
        observed_provider: observed_provider, observed_model: observed_model, usage: usage, usage_status: usage_status)
    end
  end
end
