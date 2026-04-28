# frozen_string_literal: true

module Redwright
  class DaemonRunner
    def initialize(
      ingress_poller:,
      event_handler:,
      sleeper: ->(seconds) { sleep(seconds) },
      trap_handler: nil,
      turn_queue: nil,
      queue_drain_mode: "all"
    )
      @ingress_poller = ingress_poller
      @event_handler = event_handler
      @sleeper = sleeper
      @trap_handler = trap_handler || ->(signal, &block) { Signal.trap(signal, &block) }
      @turn_queue = turn_queue
      @queue_drain_mode = queue_drain_mode
      @stop_requested = false
    end

    def run(loop_interval_seconds:, max_iterations: nil)
      install_signal_handlers
      iterations = 0

      until @stop_requested
        iterations += 1
        enqueue_events(@ingress_poller.call)
        dequeue_events.each do |event|
          @event_handler.call(event)
          break if @stop_requested
        end
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

    def enqueue_events(events)
      return if events.nil? || events.empty?

      if @turn_queue
        @turn_queue.enqueue_batch(events)
      else
        @current_events = events
      end
    end

    def dequeue_events
      if @turn_queue
        @turn_queue.dequeue(drain_mode: @queue_drain_mode)
      else
        events = @current_events || []
        @current_events = []
        events
      end
    end
  end
end
