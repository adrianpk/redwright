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

    runner.run(loop_interval_seconds: 0.001)

    assert_equal(2, polled)
    assert_equal(["event-1", "event-2"], handled)
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

    runner.run(loop_interval_seconds: 0.001)

    assert_equal(1, polled)
    assert(handlers.key?("INT"))
    assert(handlers.key?("TERM"))
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

    runner.run(loop_interval_seconds: 0.001, max_iterations: 1)

    assert_equal(1, polled)
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

    runner.run(loop_interval_seconds: 0.001, max_iterations: 2)

    assert_equal(%w[e1 e2], handled)
    assert_equal(1, queue.size)
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

    runner.run(loop_interval_seconds: 0.001, max_iterations: 1)

    assert_equal(%w[e1 e2 e3], handled)
    assert_equal(0, queue.size)
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
end
