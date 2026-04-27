# frozen_string_literal: true

require "optparse"
require_relative "redwright/bootstrap"
require_relative "redwright/paths"
require_relative "redwright/project_store"

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
      when "project"
        run_project
      else
        @err.puts("usage: redwright <bootstrap|project>")
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

    def run_project
      mode = :dev
      sub = @argv.shift
      path = nil
      aliases = []

      parser = OptionParser.new do |opts|
        opts.on("--dev", "Use ./_workspace") { mode = :dev }
        opts.on("--real", "Use $HOME paths") { mode = :real }
        opts.on("--path PATH", "Project path") { |v| path = v }
        opts.on("--alias VALUE", "Project alias (repeatable)") { |v| aliases << v }
      end

      parser.parse!(@argv)
      bootstrap = Bootstrap.new(mode: mode).call
      store = ProjectStore.new(bootstrap.db_path)

      case sub
      when "register"
        raise OptionParser::MissingArgument, "--path" if path.nil? || path.empty?

        record = store.register(path: path, aliases: aliases)
        print_record(record)
        0
      when "resolve"
        ref = @argv.shift
        record = store.resolve(ref)
        if record
          print_record(record)
          0
        else
          @err.puts("project not found")
          2
        end
      else
        @err.puts("usage: redwright project <register|resolve> [--dev|--real] ...")
        1
      end
    rescue OptionParser::ParseError => e
      @err.puts(e.message)
      1
    end

    def print_record(record)
      @out.puts("id: #{record.id}")
      @out.puts("name: #{record.name}")
      @out.puts("path: #{record.path}")
      @out.puts("aliases: #{record.aliases.join(",")}")
      @out.puts("last_active_at: #{record.last_active_at}")
    end
  end
end
