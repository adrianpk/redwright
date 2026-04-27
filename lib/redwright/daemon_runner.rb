# frozen_string_literal: true

module Redwright
  class DaemonRunner
    def initialize(ingress_poller:, event_handler:, sleeper: ->(seconds) { sleep(seconds) }, trap_handler: nil)
      @ingress_poller = ingress_poller
      @event_handler = event_handler
      @sleeper = sleeper
      @trap_handler = trap_handler || ->(signal, &block) { Signal.trap(signal, &block) }
      @stop_requested = false
    end

    def run(loop_interval_seconds:, max_iterations: nil)
      install_signal_handlers
      iterations = 0

      until @stop_requested
        iterations += 1
        events = @ingress_poller.call
        events.each { |event| @event_handler.call(event) }
        break if @stop_requested
        break if !max_iterations.nil? && iterations >= max_iterations

        @sleeper.call(loop_interval_seconds)
      end
    end

    def request_stop
      @stop_requested = true
    end

    private

    def install_signal_handlers
      @trap_handler.call("INT") { request_stop }
      @trap_handler.call("TERM") { request_stop }
    end
  end
end
