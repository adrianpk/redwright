# frozen_string_literal: true

require "json"

module Redwright
  class RuntimeResultEnvelope
    def self.success(trace_id:, project_id:, workstream_id:, task_id:, state:)
      new(
        status: "ok",
        trace_id: trace_id,
        runtime: {
          project_id: project_id,
          workstream_id: workstream_id,
          task_id: task_id,
          state: state
        }
      )
    end

    def self.error(trace_id:, message:)
      new(
        status: "error",
        trace_id: trace_id,
        error: {
          code: "runtime_error",
          message: message
        }
      )
    end

    def self.clarify(trace_id:, message:)
      new(
        status: "clarify",
        trace_id: trace_id,
        clarify: {
          question: message
        }
      )
    end

    def initialize(status:, trace_id:, runtime: nil, error: nil, clarify: nil)
      @status = status
      @trace_id = trace_id
      @runtime = runtime
      @error = error
      @clarify = clarify
    end

    def to_h
      hash = {
        status: @status,
        trace_id: @trace_id,
        runtime: @runtime,
        error: @error,
        clarify: @clarify
      }
      hash.delete_if { |_k, v| v.nil? }
      hash
    end

    def to_json_string
      JSON.pretty_generate(to_h)
    end
  end
end
