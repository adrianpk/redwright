# frozen_string_literal: true

require "optparse"
require_relative "redwright/bootstrap"
require_relative "redwright/paths"
require_relative "redwright/project_store"
require_relative "redwright/workstream_store"
require_relative "redwright/task_store"
require_relative "redwright/task_commit_store"
require_relative "redwright/alignment_store"
require_relative "redwright/alignment_interruption_store"
require_relative "redwright/psam_store"
require_relative "redwright/alignment_question_engine"
require_relative "redwright/alignment_sufficiency_heuristic"
require_relative "redwright/plan_spec_store"
require_relative "redwright/runtime_flow"
require_relative "redwright/primitive_executor"
require_relative "redwright/action_execution_store"
require_relative "redwright/worktree_manager"
require_relative "redwright/skill_dispatcher"
require_relative "redwright/skill_loader"
require_relative "redwright/skill_registry"
require_relative "redwright/spec_promotion"
require_relative "redwright/runtime_config_store"
require_relative "redwright/app_config"
require_relative "redwright/daemon_runner"
require_relative "redwright/turn_message_queue"
require_relative "redwright/telegram_client"
require_relative "redwright/telegram_ingress"
require_relative "redwright/ingress_port"
require_relative "redwright/telegram_ingress_adapter"
require_relative "redwright/simulated_ingress_adapter"
require_relative "redwright/telegram_runtime_handler"
require_relative "redwright/console/ingress_adapter"
require_relative "redwright/tui/shell"
require_relative "redwright/tui/ingress_adapter"
require_relative "redwright/tui/socket_client_runner"
require_relative "redwright/chat_context_store"
require_relative "redwright/clarification_session_store"
require_relative "redwright/telegram_context_resolver"
require_relative "redwright/model_resolver"
require_relative "redwright/openai_client"
require_relative "redwright/llm_intent_interpreter"
require_relative "redwright/prompt_context_loader"
require_relative "redwright/planner_rejection_store"
require_relative "redwright/quality_gate_runner"
require_relative "redwright/hint_normalizer"
require_relative "redwright/runtime_lock"
require_relative "redwright/local_ipc_server"
require_relative "redwright/local_ipc_session_registry"
require_relative "redwright/server_runtime_dispatcher"
require_relative "redwright/local_ipc_client"
require_relative "redwright/telegram_socket_client_runner"

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
      when "trace"
        run_trace
      when "daemon"
        run_daemon
      when "server"
        run_server
      else
        @err.puts("usage: redwright <bootstrap|project|workstream|task|flow|worktree|spec|config|trace|daemon|server>")
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
        alignment_interruption_store: AlignmentInterruptionStore.new(bootstrap.db_path),
        psam_store: PsamStore.new(bootstrap.db_path),
        alignment_question_engine: AlignmentQuestionEngine.new(llm_client: nil),
        alignment_max_turns: 8,
        alignment_sufficiency_heuristic: AlignmentSufficiencyHeuristic.new,
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
        opts.on("--ingress VALUE", "Ingress mode: telegram|console|none") { |v| ingress = v }
      end
      parser.parse!(@argv)

      case sub
      when "run"
        unless %w[telegram console tui none].include?(ingress)
          raise ArgumentError, "invalid ingress mode: #{ingress} (expected telegram|console|tui|none)"
        end

        bootstrap = Bootstrap.new(mode: mode).call
        config = AppConfigLoader.new(mode: mode).load(ingress: ingress)
        socket_path = File.join(bootstrap.state_dir, "rw.sock")

        @out.puts("daemon starting")
        @out.puts("mode: #{mode}")
        @out.puts("ingress: #{ingress}")
        @out.puts("once: #{run_once}")
        @out.puts("loop_interval_ms: #{config.runtime.loop_interval_ms}")
        @out.puts("queue_drain_mode: #{config.runtime.queue_drain_mode}")
        @out.puts("socket_path: #{socket_path}")

        if ingress == "tui"
          tui_runner = Tui::SocketClientRunner.new(input: $stdin, output: @out, socket_path: socket_path)
          tui_runner.run_once
        elsif ingress == "telegram"
          telegram_client = TelegramClient.new(bot_token: config.telegram.bot_token)
          ingress_port = TelegramIngressAdapter.new(
            client: telegram_client,
            allowed_chat_ids: config.telegram.allowed_chat_ids
          )
          tg_runner = TelegramSocketClientRunner.new(
            ingress_port: ingress_port,
            socket_path: socket_path,
            out: @out,
            poll_interval_seconds: config.telegram.poll_interval_seconds
          )
          if run_once
            tg_runner.run_once
          else
            loop do
              tg_runner.run_once
              sleep(config.runtime.loop_interval_ms / 1000.0)
            end
          end
        elsif ingress == "console"
          console = Console::IngressAdapter.new(input: $stdin, output: @out)
          poll = console.poll(cursor: nil, timeout_seconds: 0)
          event = poll.events.first
          if event
            response = LocalIpcClient.new(socket_path: socket_path).request(
              type: "send",
              session_id: "console-#{event.chat_id}",
              payload: {
                "channel" => "console",
                "project_ref" => event.text.to_s.strip.split(/\s+/).first.to_s,
                "intent" => "change",
                "message" => event.text.to_s,
                "actions" => []
              }
            )
            console.send_message(chat_id: event.chat_id, text: "status=#{response.dig('payload', 'status')}")
          end
        elsif ingress == "none"
          # no-op
        else
          raise ArgumentError, "unsupported ingress in client mode: #{ingress}"
        end
        @out.puts("daemon stopped")
        0
      else
        @err.puts("usage: redwright daemon run [--dev|--real] [--once] [--ingress telegram|console|tui|none]")
        1
      end
    rescue OptionParser::ParseError, ArgumentError => e
      @err.puts(e.message)
      1
    end

    def run_trace
      mode = :dev
      sub = @argv.shift
      limit = 20

      parser = OptionParser.new do |opts|
        opts.on("--dev", "Use ./_workspace") { mode = :dev }
        opts.on("--real", "Use $HOME paths") { mode = :real }
        opts.on("--limit VALUE", Integer, "Result limit for recent traces") { |v| limit = v }
      end
      parser.parse!(@argv)

      bootstrap = Bootstrap.new(mode: mode).call
      tasks = TaskStore.new(bootstrap.db_path)
      actions = ActionExecutionStore.new(bootstrap.db_path)

      case sub
      when "recent"
        rows = tasks.list_recent_with_trace(limit: limit)
        if rows.empty?
          @out.puts("no trace records")
          return 0
        end
        rows.each do |row|
          @out.puts("trace_id: #{row.trace_id}")
          @out.puts("task_id: #{row.task_id}")
          @out.puts("project_id: #{row.project_id}")
          @out.puts("workstream_id: #{row.workstream_id}")
          @out.puts("intent: #{row.workstream_intent}")
          @out.puts("task_status: #{row.task_status}")
          @out.puts("task_description: #{row.task_description}")
          @out.puts("created_at: #{row.created_at}")
          @out.puts("---")
        end
        0
      when "show"
        trace_id = @argv.shift
        raise OptionParser::MissingArgument, "<trace_id>" if trace_id.nil? || trace_id.empty?

        task_rows = tasks.list_by_trace_id(trace_id)
        action_rows = actions.list_by_trace_id(trace_id)
        if task_rows.empty? && action_rows.empty?
          @out.puts("trace not found")
          return 2
        end

        @out.puts("trace_id: #{trace_id}")
        @out.puts("tasks:")
        task_rows.each do |row|
          @out.puts("  - task_id: #{row.task_id}")
          @out.puts("    project_id: #{row.project_id}")
          @out.puts("    workstream_id: #{row.workstream_id}")
          @out.puts("    intent: #{row.workstream_intent}")
          @out.puts("    status: #{row.task_status}")
          @out.puts("    description: #{row.task_description}")
          @out.puts("    created_at: #{row.created_at}")
        end
        @out.puts("actions:")
        action_rows.each do |row|
          @out.puts("  - action_id: #{row.action_id}")
          @out.puts("    type: #{row.action_type}")
          @out.puts("    status: #{row.status}")
          @out.puts("    task_id: #{row.task_id}")
          @out.puts("    error_message: #{row.error_message}") if row.error_message
          @out.puts("    created_at: #{row.created_at}")
        end
        0
      else
        @err.puts("usage: redwright trace <recent|show> [--dev|--real] [--limit N] [trace_id]")
        1
      end
    rescue OptionParser::ParseError, ArgumentError => e
      @err.puts(e.message)
      1
    end

    def run_server
      mode = :dev
      sub = @argv.shift
      run_once = false
      lock = nil
      socket_path = nil

      parser = OptionParser.new do |opts|
        opts.on("--dev", "Use ./_workspace") { mode = :dev }
        opts.on("--real", "Use $HOME paths") { mode = :real }
        opts.on("--once", "Run only one loop iteration and exit") { run_once = true }
        opts.on("--socket-path VALUE", "Override local unix socket path") { |v| socket_path = v }
      end
      parser.parse!(@argv)

      bootstrap = Bootstrap.new(mode: mode).call
      lock_path = File.join(bootstrap.state_dir, "runtime.lock")
      lock = RuntimeLock.new(lock_path: lock_path)
      socket_path ||= File.join(bootstrap.state_dir, "rw.sock")

      case sub
      when "run"
        info = lock.acquire!
        session_registry = LocalIpcSessionRegistry.new
        primitive_executor = PrimitiveExecutor.new(
          allowed_projects_root: bootstrap.projects_root,
          enforce_mutating_projects_root: true
        )
        flow = RuntimeFlow.new(
          project_store: ProjectStore.new(bootstrap.db_path),
          workstream_store: WorkstreamStore.new(bootstrap.db_path),
          task_store: TaskStore.new(bootstrap.db_path),
          alignment_store: AlignmentStore.new(bootstrap.db_path),
          alignment_interruption_store: AlignmentInterruptionStore.new(bootstrap.db_path),
          psam_store: PsamStore.new(bootstrap.db_path),
          primitive_executor: primitive_executor,
          action_execution_store: ActionExecutionStore.new(bootstrap.db_path),
          skill_dispatcher: SkillDispatcher.new
        )
        runtime_dispatcher = ServerRuntimeDispatcher.new(flow: flow, blocked_retry_attempts: 1)
        ipc_server = LocalIpcServer.new(
          socket_path: socket_path,
          dispatcher: lambda do |request|
            response = runtime_dispatcher.call(request)
            response["session_count"] = session_registry.count
            response
          end,
          session_registry: session_registry
        )
        @out.puts("server starting")
        @out.puts("mode: #{mode}")
        @out.puts("state_dir: #{bootstrap.state_dir}")
        @out.puts("lock_path: #{lock_path}")
        @out.puts("socket_path: #{socket_path}")
        @out.puts("pid: #{info.pid}")
        if run_once
          ipc_server.run_once
        else
          stop_requested = false
          trap_handler = ->(signal, &block) { Signal.trap(signal, &block) }
          trap_handler.call("INT") { stop_requested = true }
          trap_handler.call("TERM") { stop_requested = true }
          until stop_requested
            ipc_server.run_once
          end
        end
        ipc_server.close
        @out.puts("server stopped")
        0
      when "status"
        running = lock.running?
        info = lock.current_info
        @out.puts("status: #{running ? 'running' : 'stopped'}")
        @out.puts("lock_path: #{lock_path}")
        @out.puts("socket_path: #{socket_path}")
        @out.puts("pid: #{info&.pid || 'none'}")
        0
      when "ping"
        if lock.running?
          @out.puts("pong")
          0
        else
          @out.puts("no_server")
          2
        end
      when "ctl"
        command = @argv.shift.to_s
        raise ArgumentError, "missing ctl command" if command.empty?

        response = LocalIpcClient.new(socket_path: socket_path).request(
          type: "ctl",
          session_id: "server-ctl",
          payload: { "channel" => "ctl", "command" => command }
        )
        @out.puts("status: #{response.dig('payload', 'status')}")
        @out.puts("command: #{response.dig('payload', 'command')}")
        @out.puts("message: #{response.dig('payload', 'message')}")
        0
      else
        @err.puts("usage: redwright server <run|status|ping|ctl> [--dev|--real] [--once]")
        1
      end
    rescue OptionParser::ParseError, ArgumentError, RuntimeError => e
      @err.puts(e.message)
      1
    ensure
      lock&.release! if sub == "run"
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

    def llm_client_for(provider)
      case provider.to_s
      when "openai"
        OpenAIClient.new
      else
        nil
      end
    end
  end
end
