# frozen_string_literal: true

module Redwright
  class TurnMessageQueue
    def initialize
      @items = []
    end

    def enqueue(event)
      @items << event
    end

    def enqueue_batch(events)
      events.each { |event| enqueue(event) }
    end

    def dequeue(drain_mode: "all")
      normalized = normalize_drain_mode(drain_mode)
      return [] if @items.empty?

      if normalized == "one"
        [@items.shift]
      else
        items = @items.dup
        @items.clear
        items
      end
    end

    def size
      @items.size
    end

    private

    def normalize_drain_mode(raw)
      value = raw.to_s.strip.downcase
      return "one" if value == "one"

      "all"
    end
  end
end
