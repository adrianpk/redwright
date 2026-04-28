# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/turn_message_queue"

class TurnMessageQueueTest < Minitest::Test
  def test_dequeue_all_drains_entire_queue
    queue = Redwright::TurnMessageQueue.new
    queue.enqueue_batch(%w[a b c])

    drained = queue.dequeue(drain_mode: "all")

    assert_equal(%w[a b c], drained)
    assert_equal(0, queue.size)
  end

  def test_dequeue_one_drains_single_item
    queue = Redwright::TurnMessageQueue.new
    queue.enqueue_batch(%w[a b c])

    drained = queue.dequeue(drain_mode: "one")

    assert_equal(["a"], drained)
    assert_equal(2, queue.size)
  end

  def test_invalid_drain_mode_defaults_to_all
    queue = Redwright::TurnMessageQueue.new
    queue.enqueue_batch(%w[a b])

    drained = queue.dequeue(drain_mode: "invalid")

    assert_equal(%w[a b], drained)
    assert_equal(0, queue.size)
  end
end
