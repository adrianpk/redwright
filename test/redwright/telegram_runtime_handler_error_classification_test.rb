# frozen_string_literal: true

require "stringio"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_runtime_handler"

class TelegramRuntimeHandlerErrorClassificationTest < Minitest::Test
  class NullTelegramClient
    def send_message(chat_id:, text:)
      _ = chat_id
      _ = text
    end
  end

  def test_runtime_error_classification_recognizes_recoverable_patterns
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: Object.new,
      telegram_client: NullTelegramClient.new,
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1
    )

    assert_equal("execution_error", handler.send(:classify_runtime_error, "path_outside_project"))
    assert_equal("macro_shape_error", handler.send(:classify_runtime_error, "write_files_missing_files"))
    assert_equal("execution_error", handler.send(:classify_runtime_error, "unexpected nil dereference"))
    assert_equal(true, handler.send(:recoverable_runtime_error?, "action_failed id=a1 error=path_outside_project"))
    assert_equal(false, handler.send(:recoverable_runtime_error?, "unexpected nil dereference"))
  end
end
