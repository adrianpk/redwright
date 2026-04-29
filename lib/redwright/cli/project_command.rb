# frozen_string_literal: true

require "optparse"

module Redwright
  class CLI
    class ProjectCommand
      def initialize(argv:, out:, err:, print_project_record:)
        @argv = argv
        @out = out
        @err = err
        @print_project_record = print_project_record
      end

      def run
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
          @print_project_record.call(record)
          0
        when "resolve"
          ref = @argv.shift
          record = store.resolve(ref)
          if record
            @print_project_record.call(record)
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
    end
  end
end
