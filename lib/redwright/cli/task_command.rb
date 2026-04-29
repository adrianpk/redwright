# frozen_string_literal: true

require "optparse"

module Redwright
  class CLI
    class TaskCommand
      def initialize(argv:, out:, err:, print_task_record:, print_task_commit:)
        @argv = argv
        @out = out
        @err = err
        @print_task_record = print_task_record
        @print_task_commit = print_task_commit
      end

      def run
        mode = :dev
        sub = @argv.shift
        workstream_id = nil
        description = nil
        status = "pending"

        parser = OptionParser.new do |opts|
          opts.on("--dev", "Use ./_workspace") { mode = :dev }
          opts.on("--real", "Use $HOME paths") { mode = :real }
          opts.on("--workstream VALUE", "Workstream id") { |v| workstream_id = v }
          opts.on("--description VALUE", "Task description") { |v| description = v }
          opts.on("--status VALUE", "Task status") { |v| status = v }
        end

        parser.parse!(@argv)
        bootstrap = Bootstrap.new(mode: mode).call
        task_store = TaskStore.new(bootstrap.db_path)
        commit_store = TaskCommitStore.new(bootstrap.db_path)

        case sub
        when "create"
          raise OptionParser::MissingArgument, "--workstream" if workstream_id.nil? || workstream_id.empty?
          raise OptionParser::MissingArgument, "--description" if description.nil? || description.empty?

          record = task_store.create(workstream_id: workstream_id, description: description, status: status)
          @print_task_record.call(record)
          0
        when "list"
          rows = task_store.list(workstream_id: workstream_id)
          rows.each { |row| @print_task_record.call(row) }
          0
        when "commit-add"
          task_id = @argv.shift
          commit_sha = @argv.shift
          raise OptionParser::MissingArgument, "<task_id>" if task_id.nil? || task_id.empty?
          raise OptionParser::MissingArgument, "<commit_sha>" if commit_sha.nil? || commit_sha.empty?

          rows = commit_store.add(task_id: task_id, commit_sha: commit_sha)
          rows.each { |row| @print_task_commit.call(row) }
          0
        when "commit-list"
          task_id = @argv.shift
          raise OptionParser::MissingArgument, "<task_id>" if task_id.nil? || task_id.empty?

          rows = commit_store.list(task_id: task_id)
          rows.each { |row| @print_task_commit.call(row) }
          0
        else
          @err.puts("usage: redwright task <create|list|commit-add|commit-list> [--dev|--real] ...")
          1
        end
      rescue OptionParser::ParseError => e
        @err.puts(e.message)
        1
      end
    end
  end
end
