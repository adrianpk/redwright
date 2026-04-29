# frozen_string_literal: true

require "timeout"

module Redwright
  class RuntimeStepTimeoutError < StandardError
    attr_reader :step, :timeout_seconds

    def initialize(step:, timeout_seconds:)
      @step = step
      @timeout_seconds = timeout_seconds
      super("runtime_step_timeout step=#{step} timeout_seconds=#{timeout_seconds}")
    end
  end

  class IngressPollTimeoutError < RuntimeStepTimeoutError; end
  class EventHandleTimeoutError < RuntimeStepTimeoutError; end
  class SleepStepTimeoutError < RuntimeStepTimeoutError; end

  module RuntimeStepTimeout
    module_function

    def with_timeout(step:, timeout_seconds:, error_class:)
      return yield if timeout_seconds.nil?

      Timeout.timeout(timeout_seconds) { yield }
    rescue Timeout::Error
      raise error_class.new(step: step, timeout_seconds: timeout_seconds)
    end
  end
end

