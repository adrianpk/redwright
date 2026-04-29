# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require_relative "../../lib/redwright"

class RuntimeEntrypointShimTest < Minitest::Test
  def test_delegates_to_cli_and_preserves_usage_behavior
    out = StringIO.new
    err = StringIO.new

    code = Redwright::RuntimeEntrypointShim.run(argv: ["unknown-command"], out: out, err: err)

    assert_equal(1, code)
    assert_includes(err.string, "usage: redwright")
  end
end
