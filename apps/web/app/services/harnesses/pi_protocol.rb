module Harnesses
  class PiProtocol
    MAX_RECORD_BYTES = 16 * 1024 * 1024
    THINKING_LEVELS = %w[off minimal low medium high xhigh max].freeze

    def initialize(request)
      @request = request
      @binding = request.binding
      @buffer = "".b
      @scan_offset = 0
      @sequence = 0
    end

    def start(input)
      command(input, "new_session")
    end

    def feed(input, chunk)
      @buffer << chunk
      while (index = @buffer.index("\n", @scan_offset))
        fail_protocol! if index > MAX_RECORD_BYTES
        line = @buffer.byteslice(0, index)
        @buffer = @buffer.byteslice(index + 1..)
        @scan_offset = 0
        line = line.delete_suffix("\r").force_encoding(Encoding::UTF_8)
        fail_protocol! unless line.valid_encoding?
        record = JSON.parse(line)
        fail_protocol! unless record.is_a?(Hash) && record["type"].is_a?(String)
        dispatch(input, record)
      end
      @scan_offset = @buffer.bytesize
      fail_protocol! if @buffer.bytesize > MAX_RECORD_BYTES
    rescue JSON::ParserError
      fail_protocol!
    end

    def finish
      fail_protocol! unless @buffer.empty? && @done && @accepted && @settled && @final
      Result.new(bytes: @final.fetch(:text), observed_provider: @final.fetch(:provider),
        observed_model: @final.fetch(:model), usage: @final[:usage], usage_status: @final.fetch(:usage_status),
        binding_digest: CanonicalJson.digest(@binding))
    end

    private

    def command(input, type, fields = {})
      fail_protocol! if @waiting || @sequence >= 16
      @sequence += 1
      @waiting = {"id" => "#{@request.request_id}:#{@sequence}", "type" => type}
      input.write(JSON.generate(@waiting.merge(fields)) + "\n")
    end

    def dispatch(input, record)
      type = record.fetch("type")
      fail_protocol! if @done && type != "session_info_changed"
      case type
      when "response" then response(input, record)
      when "agent_start"
        fail_protocol! unless @prompt_sent && !@started && !@ended
        @started = true
      when "message_end" then message_end(record["message"])
      when "message_update"
        fail_protocol! unless @started && !@ended && !@final
        update = record["assistantMessageEvent"]
        fail_protocol! unless update.is_a?(Hash)
        unsupported! if update["type"].to_s.start_with?("toolcall_")
        raise Error.new("The Pi provider stream failed.", code: :provider_error) if update["type"] == "error"
        fail_protocol! unless %w[start done text_start text_delta text_end thinking_start thinking_delta thinking_end].include?(update["type"])
      when "agent_end"
        fail_protocol! unless @started && !@ended && @final && record["willRetry"] == false && record["messages"].is_a?(Array)
        messages = record["messages"].select { |message| message.is_a?(Hash) && message["role"] == "assistant" }
        fail_protocol! unless messages.size == 1 && signature(final_message(messages.first)) == @signature
        unsupported! if record["messages"].any? { |message| message.is_a?(Hash) && message["role"] == "toolResult" }
        @ended = true
      when "agent_settled"
        raise Error.new("The Pi run was aborted.", code: :cancelled) if record["aborted"] == true
        fail_protocol! unless @ended && !@settled && record["aborted"] == false
        @settled = true
        verify_settlement(input)
      when "queue_update"
        fail_protocol! unless record["steering"] == [] && record["followUp"] == []
      when "turn_end"
        fail_protocol! unless @started && !@ended
        unsupported! unless record["toolResults"] == []
      when "turn_start", "message_start"
        fail_protocol! unless @prompt_sent && !@ended
      when "thinking_level_changed"
        if @binding["thinking"] && record["level"] != @binding["thinking"]
          raise Error.new("Pi changed the selected thinking level.", code: :unsupported_capability)
        end
      when "session_info_changed"
        nil
      when "extension_ui_request", "extension_error", "entry_appended", "bash_execution_update"
        unsupported!
      else
        unsupported! if type.start_with?("tool_execution_")
        # Auto-retry, compaction and any unknown work are outside this call's policy.
        fail_protocol!
      end
    end

    def response(input, record)
      fail_protocol! unless @waiting && record["id"] == @waiting["id"] && record["command"] == @waiting["type"]
      type = @waiting.fetch("type")
      @waiting = nil
      unless record["success"] == true
        raise Error.new("Pi rejected the structured-call command.", code: :provider_error)
      end
      data = record["data"]
      case type
      when "new_session"
        fail_protocol! unless data.is_a?(Hash) && data["cancelled"] == false
        command(input, "set_auto_retry", "enabled" => false)
      when "set_auto_retry" then command(input, "set_auto_compaction", "enabled" => false)
      when "set_auto_compaction"
        command(input, "set_model", "provider" => @binding.fetch("requested_provider"), "modelId" => @binding.fetch("requested_model"))
      when "set_model"
        verify_model!(data)
        if @binding["thinking"]
          command(input, "get_available_thinking_levels")
        else
          command(input, "get_state")
        end
      when "get_available_thinking_levels"
        unless data.is_a?(Hash) && data["levels"].is_a?(Array) && data["levels"].include?(@binding["thinking"])
          raise Error.new("The selected Pi model does not support the requested thinking level.", code: :unsupported_capability)
        end
        command(input, "set_thinking_level", "level" => @binding.fetch("thinking"))
      when "set_thinking_level" then command(input, "get_state")
      when "get_state"
        verify_state!(data)
        if @checking_final
          @done = true
          input.close
        else
          @prompt_sent = true
          message = @request.prompt + "\nOutput JSON Schema:\n" + JSON.generate(@request.schema)
          command(input, "prompt", "message" => message)
        end
      when "prompt"
        fail_protocol! unless data.is_a?(Hash) && data["disposition"] == "started"
        @accepted = true
        verify_settlement(input)
      else fail_protocol!
      end
    end

    def verify_model!(model)
      fail_protocol! unless model.is_a?(Hash) && model["provider"] == @binding["requested_provider"] && model["id"] == @binding["requested_model"]
    end

    def verify_state!(state)
      fail_protocol! unless state.is_a?(Hash) && state["isStreaming"] == false && state["isCompacting"] == false &&
        state["pendingMessageCount"] == 0 && state["autoCompactionEnabled"] == false && state["sessionFile"].nil?
      verify_model!(state["model"])
      if @binding["thinking"] && state["thinkingLevel"] != @binding["thinking"]
        raise Error.new("Pi did not retain the requested thinking level.", code: :unsupported_capability)
      end
    end

    def verify_settlement(input)
      return unless @accepted && @settled
      fail_protocol! if @checking_final
      @checking_final = true
      command(input, "get_state")
    end

    def message_end(message)
      fail_protocol! unless message.is_a?(Hash)
      case message["role"]
      when "assistant"
        fail_protocol! unless @started && !@ended && !@final
        @final = final_message(message)
        @signature = signature(@final)
      when "toolResult" then unsupported!
      when "user", "system"
        fail_protocol! unless @prompt_sent && !@ended
      else fail_protocol!
      end
    end

    def final_message(message)
      case message["stopReason"]
      when "aborted" then raise Error.new("The Pi provider call was aborted.", code: :cancelled)
      when "error" then raise Error.new("The Pi provider call failed.", code: :provider_error)
      when "toolUse", "deferred" then unsupported!
      when "stop" then nil
      else fail_protocol!
      end
      fail_protocol! unless message["provider"] == @binding["requested_provider"] && message["model"] == @binding["requested_model"] && message["content"].is_a?(Array)
      text = +""
      message["content"].each do |block|
        fail_protocol! unless block.is_a?(Hash)
        case block["type"]
        when "text"
          fail_protocol! unless block["text"].is_a?(String)
          text << block["text"]
          raise Error.new("The Pi result is too large.", code: :output_too_large) if text.bytesize > @request.max_output_bytes
        when "thinking" then nil
        else unsupported!
        end
      end
      model = message.fetch("responseModel", message["model"])
      fail_protocol! unless model.is_a?(String) && model.bytesize.between?(1, 256)
      usage = usage_values(message["usage"])
      {text: text.freeze, model: model, provider: message["provider"], usage: usage,
        usage_status: usage.nil? ? :unknown : (%w[input output cacheRead cacheWrite totalTokens].all? { |key| usage.key?(key) } ? :known : :partial)}
    end

    def usage_values(value)
      return if value.nil?
      fail_protocol! unless value.is_a?(Hash)
      fields = %w[input output cacheRead cacheWrite cacheWrite1h reasoning totalTokens]
      result = value.slice(*fields)
      fail_protocol! unless result.values.all? { |item| item.is_a?(Integer) && item.between?(0, 2**63 - 1) }
      result.empty? ? nil : result.freeze
    end

    def signature(value)
      [Digest::SHA256.hexdigest(value.fetch(:text)), value.fetch(:provider), value.fetch(:model)]
    end

    def fail_protocol!
      raise Error.new("Pi returned an invalid or incomplete RPC sequence.", code: :protocol_error)
    end

    def unsupported!
      raise Error.new("Pi requested work outside the admitted tool-free capability.", code: :unsupported_capability)
    end
  end
end
