# frozen_string_literal: true

require "time"

module Redwright
  class LocalIpcSessionRegistry
    Session = Struct.new(:session_id, :channel, :subscribed, :created_at, :updated_at, keyword_init: true)

    def initialize(now_provider: -> { Time.now.utc.iso8601(6) })
      @now_provider = now_provider
      @sessions = {}
    end

    def upsert(session_id:, channel:, subscribed:)
      now = @now_provider.call
      prev = @sessions[session_id]
      @sessions[session_id] = Session.new(
        session_id: session_id,
        channel: channel,
        subscribed: subscribed,
        created_at: prev ? prev.created_at : now,
        updated_at: now
      )
    end

    def get(session_id)
      @sessions[session_id]
    end

    def count
      @sessions.size
    end
  end
end
