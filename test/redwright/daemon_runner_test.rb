# frozen_string_literal: true

require "minitest/autorun"
require "timeout"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/daemon_runner"
require "redwright/turn_message_queue"

class DaemonRunnerTest < Minitest::Test
  def test_run_polls_events_until_stop_requested
    polled = 0
    handled = []
    sleeps = 0
    runner = nil

    runner = Redwright::DaemonRunner.new(
      ingress_poller: lambda {
        polled += 1
        ["event-#{polled}"]
      },
      event_handler: ->(event) { handled << event },
      sleeper: lambda { |_seconds|
        sleeps += 1
        runner.request_stop if sleeps >= 2
      },
      trap_handler: ->(_signal, &_block) {}
    )

    result = runner.run(loop_interval_seconds: 0.001)

    assert_equal(2, polled)
    assert_equal(["event-1", "event-2"], handled)
    assert_equal("stop_requested", result.stopped_reason)
  end

  def test_signal_handlers_request_stop
    handlers = {}
    polled = 0

    runner = Redwright::DaemonRunner.new(
      ingress_poller: lambda {
        polled += 1
        handlers["TERM"].call if handlers["TERM"]
        []
      },
      event_handler: ->(_event) {},
      sleeper: ->(_seconds) {},
      trap_handler: ->(signal, &block) { handlers[signal] = block }
    )

    result = runner.run(loop_interval_seconds: 0.001)

    assert_equal(1, polled)
    assert(handlers.key?("INT"))
    assert(handlers.key?("TERM"))
    assert_equal("stop_requested", result.stopped_reason)
  end

  def test_run_stops_after_max_iterations
    polled = 0
    runner = Redwright::DaemonRunner.new(
      ingress_poller: lambda {
        polled += 1
        []
      },
      event_handler: ->(_event) {},
      sleeper: ->(_seconds) {},
      trap_handler: ->(_signal, &_block) {}
    )

    result = runner.run(loop_interval_seconds: 0.001, max_iterations: 1)

    assert_equal(1, polled)
    assert_equal("max_iterations", result.stopped_reason)
  end

  def test_run_with_turn_queue_drains_one_per_iteration
    polled = 0
    handled = []
    queue = Redwright::TurnMessageQueue.new
    runner = Redwright::DaemonRunner.new(
      ingress_poller: lambda {
        polled += 1
        polled == 1 ? %w[e1 e2 e3] : []
      },
      event_handler: ->(event) { handled << event },
      sleeper: ->(_seconds) {},
      trap_handler: ->(_signal, &_block) {},
      turn_queue: queue,
      queue_drain_mode: "one"
    )

    result = runner.run(loop_interval_seconds: 0.001, max_iterations: 2)

    assert_equal(%w[e1 e2], handled)
    assert_equal(1, queue.size)
    assert_equal("max_iterations", result.stopped_reason)
    assert_equal(1, result.pending_events_count)
  end

  def test_run_with_turn_queue_drains_all_per_iteration
    polled = 0
    handled = []
    queue = Redwright::TurnMessageQueue.new
    runner = Redwright::DaemonRunner.new(
      ingress_poller: lambda {
        polled += 1
        polled == 1 ? %w[e1 e2 e3] : []
      },
      event_handler: ->(event) { handled << event },
      sleeper: ->(_seconds) {},
      trap_handler: ->(_signal, &_block) {},
      turn_queue: queue,
      queue_drain_mode: "all"
    )

    result = runner.run(loop_interval_seconds: 0.001, max_iterations: 1)

    assert_equal(%w[e1 e2 e3], handled)
    assert_equal(0, queue.size)
    assert_equal("max_iterations", result.stopped_reason)
    assert_equal(0, result.pending_events_count)
  end

  def test_run_raises_ingress_poll_timeout_error
    runner = Redwright::DaemonRunner.new(
      ingress_poller: lambda {
        sleep 0.05
        []
      },
      event_handler: ->(_event) {},
      sleeper: ->(_seconds) {},
      trap_handler: ->(_signal, &_block) {},
      ingress_poll_timeout_seconds: 0.01
    )

    error = assert_raises(Redwright::IngressPollTimeoutError) do
      runner.run(loop_interval_seconds: 0.001, max_iterations: 1)
    end
    assert_equal("ingress_poll", error.step)
  end

  def test_run_raises_event_handle_timeout_error
    runner = Redwright::DaemonRunner.new(
      ingress_poller: -> { ["e1"] },
      event_handler: ->(_event) { sleep 0.05 },
      sleeper: ->(_seconds) {},
      trap_handler: ->(_signal, &_block) {},
      event_handle_timeout_seconds: 0.01
    )

    error = assert_raises(Redwright::EventHandleTimeoutError) do
      runner.run(loop_interval_seconds: 0.001, max_iterations: 1)
    end
    assert_equal("event_handle", error.step)
  end

  def test_run_raises_sleep_step_timeout_error
    runner = Redwright::DaemonRunner.new(
      ingress_poller: -> { [] },
      event_handler: ->(_event) {},
      sleeper: ->(_seconds) { sleep 0.05 },
      trap_handler: ->(_signal, &_block) {},
      sleep_step_timeout_seconds: 0.01
    )

    error = assert_raises(Redwright::SleepStepTimeoutError) do
      runner.run(loop_interval_seconds: 0.001, max_iterations: 2)
    end
    assert_equal("loop_sleep", error.step)
  end

  def test_run_stops_on_cancel_request_and_preserves_pending_queue
    queue = Redwright::TurnMessageQueue.new
    cancel = false
    handled = 0
    runner = Redwright::DaemonRunner.new(
      ingress_poller: -> { %w[e1 e2 e3] },
      event_handler: lambda { |_event|
        handled += 1
        cancel = true if handled >= 1
      },
      sleeper: ->(_seconds) {},
      trap_handler: ->(_signal, &_block) {},
      turn_queue: queue,
      queue_drain_mode: "one"
    )

    result = runner.run(
      loop_interval_seconds: 0.001,
      cancel_requested: -> { cancel }
    )

    assert_equal("cancel_requested", result.stopped_reason)
    assert_equal(2, result.pending_events_count)
  end
end
