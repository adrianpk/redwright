# frozen_string_literal: true

require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/openai_client"

class OpenAIClientTest < Minitest::Test
  Response = Struct.new(:code, :body)

  def test_complete_json_posts_expected_payload_and_parses_completion
    captured = {}
    client = Redwright::OpenAIClient.new(
      api_key: "test-key",
      base_url: "https://api.example.test/v1",
      http_post: lambda do |uri:, payload:, timeout_seconds:, api_key:|
        captured[:uri] = uri.to_s
        captured[:payload] = payload
        captured[:timeout_seconds] = timeout_seconds
        captured[:api_key] = api_key
        Response.new(
          "200",
          JSON.generate({
            choices: [
              {
                finish_reason: "stop",
                message: { content: "{\"intent\":\"change\",\"message\":\"do x\"}" }
              }
            ]
          })
        )
      end
    )

    completion = client.complete_json(
      model: "gpt-5-mini",
      system_prompt: "system",
      user_text: "user text"
    )

    assert_equal("https://api.example.test/v1/chat/completions", captured[:uri])
    assert_equal("test-key", captured[:api_key])
    assert_equal("gpt-5-mini", captured[:payload][:model])
    assert_equal("json_object", captured[:payload].dig(:response_format, :type))
    assert_equal("system", captured[:payload][:messages][0][:content])
    assert_equal("user text", captured[:payload][:messages][1][:content])
    assert_equal("{\"intent\":\"change\",\"message\":\"do x\"}", completion.content)
    assert_equal("stop", completion.finish_reason)
  end

  def test_complete_json_requires_api_key
    client = Redwright::OpenAIClient.new(api_key: "")
    err = assert_raises(ArgumentError) do
      client.complete_json(model: "gpt-5-mini", system_prompt: "s", user_text: "u")
    end
    assert_equal("openai api key is missing", err.message)
  end
end
