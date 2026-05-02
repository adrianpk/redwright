module Api
  module V1
    class BaseController < ActionController::API
      before_action :require_actor_context!

      private

      def request_identifier
        request_parameters["request_id"].presence ||
          request.headers["X-Request-Id"].presence ||
          request.uuid
      end

      def actor_context
        context = request_parameters["execution_context"].is_a?(Hash) ? request_parameters["execution_context"] : {}
        actor = request.headers["X-Redwright-Actor"].presence ||
          context["actor_identifier"].presence ||
          context["actor_id"].presence

        context.merge(
          "actor_identifier" => actor.to_s,
          "source_channel" => request.headers["X-Redwright-Source"].presence || context["source_channel"].presence || "api"
        )
      end

      def require_actor_context!
        return if actor_context["actor_identifier"].present?

        render json: {
          status: "error",
          request_id: request_identifier,
          session_id: nil,
          project_id: nil,
          state: nil,
          next_prompt: nil,
          summary: "Actor context is required.",
          data: {},
          effects: [],
          errors: [
            {
              code: "missing_actor_context",
              message: "X-Redwright-Actor or execution_context.actor_identifier is required",
              details: []
            }
          ]
        }, status: :unauthorized
      end

      def request_parameters
        @request_parameters ||= params.to_unsafe_h.except("controller", "action", "kind")
      end
    end
  end
end
