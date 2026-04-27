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

    def run(loop_interval_seconds:)
      install_signal_handlers

      until @stop_requested
        events = @ingress_poller.call
        events.each { |event| @event_handler.call(event) }
        break if @stop_requested

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
