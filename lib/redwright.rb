# frozen_string_literal: true

require "optparse"
require_relative "redwright/bootstrap"
require_relative "redwright/paths"
require_relative "redwright/project_store"
require_relative "redwright/workstream_store"
require_relative "redwright/task_store"

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
      when "workstream"
        run_workstream
      when "task"
        run_task
      else
        @err.puts("usage: redwright <bootstrap|project|workstream|task>")
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
        print_project_record(record)
        0
      when "resolve"
        ref = @argv.shift
        record = store.resolve(ref)
        if record
          print_project_record(record)
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

    def run_workstream
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
        return not_found("project not found") unless project_record
        raise OptionParser::MissingArgument, "--intent" if intent.nil? || intent.empty?

        record = ws_store.create(
          project_id: project_record.id,
          intent: intent,
          state: state,
          branch: branch,
          worktree_path: worktree_path
        )
        print_workstream_record(record)
        0
      when "list"
        project_record = project ? project_store.resolve(project) : nil
        return not_found("project not found") if project && !project_record

        rows = ws_store.list(project_id: project_record&.id)
        rows.each { |row| print_workstream_record(row) }
        0
      else
        @err.puts("usage: redwright workstream <create|list> [--dev|--real] ...")
        1
      end
    rescue OptionParser::ParseError => e
      @err.puts(e.message)
      1
    end

    def run_task
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

      case sub
      when "create"
        raise OptionParser::MissingArgument, "--workstream" if workstream_id.nil? || workstream_id.empty?
        raise OptionParser::MissingArgument, "--description" if description.nil? || description.empty?

        record = task_store.create(workstream_id: workstream_id, description: description, status: status)
        print_task_record(record)
        0
      when "list"
        rows = task_store.list(workstream_id: workstream_id)
        rows.each { |row| print_task_record(row) }
        0
      else
        @err.puts("usage: redwright task <create|list> [--dev|--real] ...")
        1
      end
    rescue OptionParser::ParseError => e
      @err.puts(e.message)
      1
    end

    def print_project_record(record)
      @out.puts("id: #{record.id}")
      @out.puts("name: #{record.name}")
      @out.puts("path: #{record.path}")
      @out.puts("aliases: #{record.aliases.join(",")}")
      @out.puts("last_active_at: #{record.last_active_at}")
    end

    def print_workstream_record(record)
      @out.puts("id: #{record.id}")
      @out.puts("project_id: #{record.project_id}")
      @out.puts("intent: #{record.intent}")
      @out.puts("state: #{record.state}")
      @out.puts("branch: #{record.branch}")
      @out.puts("worktree_path: #{record.worktree_path}")
      @out.puts("updated_at: #{record.updated_at}")
    end

    def print_task_record(record)
      @out.puts("id: #{record.id}")
      @out.puts("workstream_id: #{record.workstream_id}")
      @out.puts("description: #{record.description}")
      @out.puts("status: #{record.status}")
      @out.puts("updated_at: #{record.updated_at}")
    end

    def not_found(msg)
      @err.puts(msg)
      2
    end
  end
end
