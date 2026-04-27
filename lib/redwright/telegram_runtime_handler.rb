# frozen_string_literal: true

module Redwright
  class TelegramRuntimeHandler
    def initialize(flow:, telegram_client:, out:, err:, blocked_retry_attempts:, default_intent: "change")
      @flow = flow
      @telegram_client = telegram_client
      @out = out
      @err = err
      @blocked_retry_attempts = blocked_retry_attempts
      @default_intent = default_intent
    end

    def handle(event)
      result = @flow.process(
        project_ref: nil,
        intent: @default_intent,
        message: event.text,
        confirm_new_workstream: true,
        blocked_retry_attempts: @blocked_retry_attempts
      )

      text = +"ok\n"
      text << "project_id: #{result.project.id}\n"
      text << "workstream_id: #{result.workstream.id}\n"
      text << "task_id: #{result.task.id}\n"
      text << "state: #{result.workstream.state}"
      @telegram_client.send_message(chat_id: event.chat_id, text: text)
      @out.puts("telegram processed chat=#{event.chat_id} task=#{result.task.id}")
    rescue StandardError => e
      @telegram_client.send_message(chat_id: event.chat_id, text: "error: #{e.message}")
      @err.puts("telegram processing error chat=#{event.chat_id}: #{e.message}")
    end
  end
end
