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

    def initialize(status:, trace_id:, runtime: nil, error: nil)
      @status = status
      @trace_id = trace_id
      @runtime = runtime
      @error = error
    end

    def to_h
      hash = {
        status: @status,
        trace_id: @trace_id,
        runtime: @runtime,
        error: @error
      }
      hash.delete_if { |_k, v| v.nil? }
      hash
    end

    def to_json_string
      JSON.pretty_generate(to_h)
    end
  end
end
