# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/daemon_runner"

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
end
