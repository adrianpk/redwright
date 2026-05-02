module Api
  module V1
    class CommandQueriesController < BaseController
      def create
        result = command_query_dispatcher.call(envelope_hash)
        render json: command_query_response_body(result), status: response_status(result)
      end

      private

      def command_query_dispatcher
        CommandQuery::ApplicationDispatcher.build
      end

      def envelope_hash
        {
          "kind" => params[:kind].to_s,
          "name" => request_parameters["name"],
          "payload" => object_or_empty_hash(request_parameters["payload"]),
          "execution_context" => actor_context,
          "request_id" => request_identifier
        }
      end

      def command_query_response_body(result)
        result.to_h.merge(
          session_id: result.data["session_id"],
          project_id: result.data["project_id"],
          state: result.data["state"],
          next_prompt: result.data["next_prompt"],
          summary: result.data["summary"] || result.errors.first&.fetch(:message, nil)
        )
      end

      def response_status(result)
        result.ok? ? :ok : :unprocessable_entity
      end

      def object_or_empty_hash(value)
        value.is_a?(Hash) ? value : {}
      end
    end
  end
end
