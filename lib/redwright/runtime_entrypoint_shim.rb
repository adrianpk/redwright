# frozen_string_literal: true

module Redwright
  module RuntimeEntrypointShim
    module_function

    def run(argv:, out: $stdout, err: $stderr)
      CLI.new(argv, out: out, err: err).run
    end
  end
end
