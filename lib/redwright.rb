# frozen_string_literal: true

require "optparse"
require_relative "redwright/bootstrap"

module Redwright
  class CLI
    def initialize(argv, out: $stdout, err: $stderr)
      @argv = argv.dup
      @out = out
      @err = err
    end

    def run
      command = @argv.shift

      case command
      when "bootstrap"
        run_bootstrap
      else
        @err.puts("usage: redwright bootstrap [--dev|--real]")
        1
      end
    end

    private

    def run_bootstrap
      mode = :dev
      parser = OptionParser.new do |opts|
        opts.on("--dev", "Bootstrap using ./_workspace") { mode = :dev }
        opts.on("--real", "Bootstrap using $HOME paths") { mode = :real }
      end

      parser.parse!(@argv)

      result = Bootstrap.new(mode: mode).call
      @out.puts("bootstrap complete")
      @out.puts("mode: #{mode}")
      @out.puts("state_dir: #{result.state_dir}")
      @out.puts("config_dir: #{result.config_dir}")
      @out.puts("projects_root: #{result.projects_root}")
      @out.puts("worktrees_root: #{result.worktrees_root}")
      @out.puts("db_path: #{result.db_path}")
      0
    rescue OptionParser::ParseError => e
      @err.puts(e.message)
      1
    end
  end
end
