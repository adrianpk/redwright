# frozen_string_literal: true

require "optparse"

module Redwright
  class CLI
    class WorkstreamCommand
      def initialize(argv:, out:, err:, print_workstream_record:, not_found:)
        @argv = argv
        @out = out
        @err = err
        @print_workstream_record = print_workstream_record
        @not_found = not_found
      end

      def run
        mode = :dev
        sub = @argv.shift
        project = nil
        intent = nil
        state = "ready"
        branch = nil
        worktree_path = nil

        parser = OptionParser.new do |opts|
          opts.on("--dev", "Use ./_workspace") { mode = :dev }
          opts.on("--real", "Use $HOME paths") { mode = :real }
          opts.on("--project VALUE", "Project id/path/alias") { |v| project = v }
          opts.on("--intent VALUE", "Workstream intent") { |v| intent = v }
          opts.on("--state VALUE", "Workstream state") { |v| state = v }
          opts.on("--branch VALUE", "Branch name") { |v| branch = v }
          opts.on("--worktree-path VALUE", "Worktree path") { |v| worktree_path = v }
        end

        parser.parse!(@argv)
        bootstrap = Bootstrap.new(mode: mode).call
        project_store = ProjectStore.new(bootstrap.db_path)
        ws_store = WorkstreamStore.new(bootstrap.db_path)

        case sub
        when "create"
          project_record = project_store.resolve(project)
          return @not_found.call("project not found") unless project_record
          raise OptionParser::MissingArgument, "--intent" if intent.nil? || intent.empty?

          record = ws_store.create(
            project_id: project_record.id,
            intent: intent,
            state: state,
            branch: branch,
            worktree_path: worktree_path
          )
          @print_workstream_record.call(record)
          0
        when "list"
          project_record = project ? project_store.resolve(project) : nil
          return @not_found.call("project not found") if project && !project_record

          rows = ws_store.list(project_id: project_record&.id)
          rows.each { |row| @print_workstream_record.call(row) }
          0
        else
          @err.puts("usage: redwright workstream <create|list> [--dev|--real] ...")
          1
        end
      rescue OptionParser::ParseError => e
        @err.puts(e.message)
        1
      end
    end
  end
end
