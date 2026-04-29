# frozen_string_literal: true

require_relative "runtime_step_timeout"

module Redwright
  class DaemonRunner
    RunResult = Struct.new(:stopped_reason, :pending_events_count, keyword_init: true)

    def initialize(
      ingress_poller:,
      event_handler:,
      sleeper: ->(seconds) { sleep(seconds) },
      trap_handler: nil,
      turn_queue: nil,
      queue_drain_mode: "all",
      ingress_poll_timeout_seconds: 30,
      event_handle_timeout_seconds: 120,
      sleep_step_timeout_seconds: 30
    )
      @ingress_poller = ingress_poller
      @event_handler = event_handler
      @sleeper = sleeper
      @trap_handler = trap_handler || ->(signal, &block) { Signal.trap(signal, &block) }
      @turn_queue = turn_queue
      @queue_drain_mode = queue_drain_mode
      @ingress_poll_timeout_seconds = ingress_poll_timeout_seconds
      @event_handle_timeout_seconds = event_handle_timeout_seconds
      @sleep_step_timeout_seconds = sleep_step_timeout_seconds
      @stop_requested = false
    end

    def run(loop_interval_seconds:, max_iterations: nil, cancel_requested: -> { false })
      install_signal_handlers
      iterations = 0
      stopped_reason = "completed"

      until @stop_requested
        if cancel_requested.call
          stopped_reason = "cancel_requested"
          break
        end

        iterations += 1
        events = RuntimeStepTimeout.with_timeout(
          step: "ingress_poll",
          timeout_seconds: @ingress_poll_timeout_seconds,
          error_class: IngressPollTimeoutError
        ) { @ingress_poller.call }
        enqueue_events(events)
        dequeue_events.each do |event|
          RuntimeStepTimeout.with_timeout(
            step: "event_handle",
            timeout_seconds: @event_handle_timeout_seconds,
            error_class: EventHandleTimeoutError
          ) { @event_handler.call(event) }
          if @stop_requested
            stopped_reason = "stop_requested"
            break
          end
          if cancel_requested.call
            stopped_reason = "cancel_requested"
            break
          end
        end
        if @stop_requested
          stopped_reason = "stop_requested"
          break
        end
        if !max_iterations.nil? && iterations >= max_iterations
          stopped_reason = "max_iterations"
          break
        end

        RuntimeStepTimeout.with_timeout(
          step: "loop_sleep",
          timeout_seconds: @sleep_step_timeout_seconds,
          error_class: SleepStepTimeoutError
        ) { @sleeper.call(loop_interval_seconds) }
        if @stop_requested
          stopped_reason = "stop_requested"
          break
        end
      end

      RunResult.new(
        stopped_reason: stopped_reason,
        pending_events_count: pending_events_count
      )
    end

    def request_stop(_reason = "requested")
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

    def pending_events_count
      if @turn_queue
        @turn_queue.size
      else
        (@current_events || []).size
      end
    end
  end
end
