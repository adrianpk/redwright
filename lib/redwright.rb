# frozen_string_literal: true

require "optparse"
require_relative "redwright/bootstrap"
require_relative "redwright/paths"
require_relative "redwright/project_store"
require_relative "redwright/workstream_store"
require_relative "redwright/task_store"
require_relative "redwright/task_commit_store"
require_relative "redwright/alignment_store"
require_relative "redwright/plan_spec_store"
require_relative "redwright/runtime_flow"
require_relative "redwright/worktree_manager"
require_relative "redwright/spec_promotion"
require_relative "redwright/runtime_config_store"
require_relative "redwright/app_config"
require_relative "redwright/daemon_runner"
require_relative "redwright/telegram_client"
require_relative "redwright/telegram_ingress"
require_relative "redwright/telegram_runtime_handler"
require_relative "redwright/model_resolver"

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
      when "flow"
        run_flow
      when "worktree"
        run_worktree
      when "spec"
        run_spec
      when "config"
        run_config
      when "daemon"
        run_daemon
      else
        @err.puts("usage: redwright <bootstrap|project|workstream|task|flow|worktree|spec|config|daemon>")
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
      commit_store = TaskCommitStore.new(bootstrap.db_path)

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
      when "commit-add"
        task_id = @argv.shift
        commit_sha = @argv.shift
        raise OptionParser::MissingArgument, "<task_id>" if task_id.nil? || task_id.empty?
        raise OptionParser::MissingArgument, "<commit_sha>" if commit_sha.nil? || commit_sha.empty?

        rows = commit_store.add(task_id: task_id, commit_sha: commit_sha)
        rows.each { |row| print_task_commit(row) }
        0
      when "commit-list"
        task_id = @argv.shift
        raise OptionParser::MissingArgument, "<task_id>" if task_id.nil? || task_id.empty?

        rows = commit_store.list(task_id: task_id)
        rows.each { |row| print_task_commit(row) }
        0
      else
        @err.puts("usage: redwright task <create|list|commit-add|commit-list> [--dev|--real] ...")
        1
      end
    rescue OptionParser::ParseError => e
      @err.puts(e.message)
      1
    end

    def run_flow
      mode = :dev
      sub = @argv.shift
      project = nil
      intent = "change"
      message = nil
      workstream_id = nil
      confirm_new_workstream = false
      blocked_retries = nil

      parser = OptionParser.new do |opts|
        opts.on("--dev", "Use ./_workspace") { mode = :dev }
        opts.on("--real", "Use $HOME paths") { mode = :real }
        opts.on("--project VALUE", "Project id/path/alias (optional, defaults to last active)") { |v| project = v }
        opts.on("--intent VALUE", "Intent for new workstream") { |v| intent = v }
        opts.on("--message VALUE", "Incoming message text") { |v| message = v }
        opts.on("--workstream VALUE", "Existing workstream id") { |v| workstream_id = v }
        opts.on("--confirm-new-workstream", "Confirm creation of a new workstream when needed") { confirm_new_workstream = true }
        opts.on("--blocked-retries VALUE", Integer, "Override blocked retry attempts") { |v| blocked_retries = v }
      end

      parser.parse!(@argv)
      bootstrap = Bootstrap.new(mode: mode).call
      config = RuntimeConfigStore.new(bootstrap.db_path)
      flow = RuntimeFlow.new(
        project_store: ProjectStore.new(bootstrap.db_path),
        workstream_store: WorkstreamStore.new(bootstrap.db_path),
        task_store: TaskStore.new(bootstrap.db_path),
        alignment_store: AlignmentStore.new(bootstrap.db_path),
        plan_spec_store: PlanSpecStore.new
      )

      case sub
      when "process"
        raise OptionParser::MissingArgument, "--message" if message.nil? || message.empty?

        result = flow.process(
          project_ref: project,
          intent: intent,
          message: message,
          workstream_id: workstream_id,
          confirm_new_workstream: confirm_new_workstream,
          blocked_retry_attempts: blocked_retries || config.blocked_retry_attempts
        )
        print_project_record(result.project)
        print_workstream_record(result.workstream)
        print_task_record(result.task)
        print_alignment_record(result.alignment) if result.alignment
        @out.puts("functional_spec_path: #{result.functional_spec_path}") if result.functional_spec_path
        @out.puts("technical_spec_path: #{result.technical_spec_path}") if result.technical_spec_path
        0
      else
        @err.puts("usage: redwright flow process [--dev|--real] ...")
        1
      end
    rescue OptionParser::ParseError, ArgumentError => e
      @err.puts(e.message)
      1
    end

    def run_worktree
      mode = :dev
      sub = @argv.shift
      workstream_id = nil
      branch = nil

      parser = OptionParser.new do |opts|
        opts.on("--dev", "Use ./_workspace") { mode = :dev }
        opts.on("--real", "Use $HOME paths") { mode = :real }
        opts.on("--workstream VALUE", "Workstream id") { |v| workstream_id = v }
        opts.on("--branch VALUE", "Branch name for create") { |v| branch = v }
      end

      parser.parse!(@argv)
      bootstrap = Bootstrap.new(mode: mode).call
      manager = WorktreeManager.new(
        project_store: ProjectStore.new(bootstrap.db_path),
        workstream_store: WorkstreamStore.new(bootstrap.db_path),
        worktrees_root: bootstrap.worktrees_root
      )

      raise OptionParser::MissingArgument, "--workstream" if workstream_id.nil? || workstream_id.empty?

      case sub
      when "create"
        raise OptionParser::MissingArgument, "--branch" if branch.nil? || branch.empty?

        ws = manager.create(workstream_id: workstream_id, branch: branch)
        print_workstream_record(ws)
        0
      when "remove"
        ws = manager.remove(workstream_id: workstream_id)
        print_workstream_record(ws)
        0
      when "status"
        status = manager.status(workstream_id: workstream_id)
        @out.puts("exists: #{status.exists}")
        @out.puts("path: #{status.path}")
        @out.puts("branch: #{status.branch}")
        0
      else
        @err.puts("usage: redwright worktree <create|remove|status> [--dev|--real] ...")
        1
      end
    rescue OptionParser::ParseError, ArgumentError => e
      @err.puts(e.message)
      1
    end

    def run_spec
      sub = @argv.shift
      promoter = SpecPromotion.new

      case sub
      when "promote"
        file_name = @argv.shift
        result = promoter.promote(file_name)
        @out.puts("promoted: #{result.source_path} -> #{result.target_path}")
        0
      else
        @err.puts("usage: redwright spec promote <draft-file-name>")
        1
      end
    rescue ArgumentError => e
      @err.puts(e.message)
      1
    end

    def run_config
      mode = :dev
      sub = @argv.shift

      parser = OptionParser.new do |opts|
        opts.on("--dev", "Use ./_workspace") { mode = :dev }
        opts.on("--real", "Use $HOME paths") { mode = :real }
      end
      parser.parse!(@argv)

      bootstrap = Bootstrap.new(mode: mode).call
      store = RuntimeConfigStore.new(bootstrap.db_path)

      case sub
      when "get"
        key = @argv.shift
        if key == "blocked_retry_attempts"
          @out.puts("blocked_retry_attempts: #{store.blocked_retry_attempts}")
          return 0
        end
      when "set"
        key = @argv.shift
        value = @argv.shift
        if key == "blocked_retry_attempts"
          updated = store.set_blocked_retry_attempts(value)
          @out.puts("blocked_retry_attempts: #{updated}")
          return 0
        end
      end

      @err.puts("usage: redwright config <get|set> blocked_retry_attempts [value]")
      1
    rescue OptionParser::ParseError, ArgumentError => e
      @err.puts(e.message)
      1
    end

    def run_daemon
      mode = :dev
      sub = @argv.shift
      run_once = false
      ingress = "telegram"

      parser = OptionParser.new do |opts|
        opts.on("--dev", "Use ./_workspace") { mode = :dev }
        opts.on("--real", "Use $HOME paths") { mode = :real }
        opts.on("--once", "Run only one loop iteration and exit") { run_once = true }
        opts.on("--ingress VALUE", "Ingress mode: telegram|none") { |v| ingress = v }
      end
      parser.parse!(@argv)

      case sub
      when "run"
        unless %w[telegram none].include?(ingress)
          raise ArgumentError, "invalid ingress mode: #{ingress} (expected telegram|none)"
        end

        bootstrap = Bootstrap.new(mode: mode).call
        config = AppConfigLoader.new(mode: mode).load
        model_resolver = ModelResolver.new(config.models)
        non_coding_model = model_resolver.resolve("non_coding")
        flow = RuntimeFlow.new(
          project_store: ProjectStore.new(bootstrap.db_path),
          workstream_store: WorkstreamStore.new(bootstrap.db_path),
          task_store: TaskStore.new(bootstrap.db_path),
          alignment_store: AlignmentStore.new(bootstrap.db_path),
          plan_spec_store: PlanSpecStore.new
        )
        telegram_client = TelegramClient.new(bot_token: config.telegram.bot_token)
        telegram_ingress = TelegramIngress.new(
          client: telegram_client,
          allowed_chat_ids: config.telegram.allowed_chat_ids
        )
        runtime_handler = TelegramRuntimeHandler.new(
          flow: flow,
          telegram_client: telegram_client,
          out: @out,
          err: @err,
          blocked_retry_attempts: config.runtime.blocked_retry_attempts,
          model_role: "non_coding",
          model_provider: non_coding_model.provider,
          model_name: non_coding_model.name
        )
        offset = nil
        runner = DaemonRunner.new(
          ingress_poller: lambda {
            next [] if ingress == "none"

            poll = telegram_ingress.poll(
              offset: offset,
              timeout_seconds: config.telegram.poll_interval_seconds
            )
            offset = poll.next_offset
            poll.events
          },
          event_handler: ->(event) { runtime_handler.handle(event) }
        )

        @out.puts("daemon starting")
        @out.puts("mode: #{mode}")
        @out.puts("ingress: #{ingress}")
        @out.puts("once: #{run_once}")
        @out.puts("loop_interval_ms: #{config.runtime.loop_interval_ms}")

        runner.run(
          loop_interval_seconds: config.runtime.loop_interval_ms / 1000.0,
          max_iterations: run_once ? 1 : nil
        )
        @out.puts("daemon stopped")
        0
      else
        @err.puts("usage: redwright daemon run [--dev|--real] [--once] [--ingress telegram|none]")
        1
      end
    rescue OptionParser::ParseError, ArgumentError => e
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

    def print_task_commit(row)
      @out.puts("task_id: #{row[:task_id]}")
      @out.puts("commit_sha: #{row[:commit_sha]}")
      @out.puts("created_at: #{row[:created_at]}")
    end

    def print_alignment_record(record)
      @out.puts("alignment_status: #{record.status}")
      @out.puts("alignment_step_index: #{record.step_index}")
      @out.puts("alignment_pending_question: #{record.pending_question}")
      @out.puts("alignment_unresolved_count: #{record.unresolved_count}")
      @out.puts("alignment_decisions_stable: #{record.decisions_stable}")
    end

    def not_found(msg)
      @err.puts(msg)
      2
    end
  end
end
