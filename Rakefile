# frozen_string_literal: true

require "shellwords"
require "open3"
require "fileutils"
require_relative "lib/redwright/local_quality"
require_relative "scripts/runtime/foreground_runner"

desc "Run full test suite"
task :test do
  sh 'bundle exec ruby -Itest -e \'Dir["test/**/*_test.rb"].sort.each { |path| require File.expand_path(path) }\''
end

desc "Bootstrap runtime paths and sqlite in --dev mode"
task :bootstrap do
  sh "bundle exec ruby bin/redwright bootstrap --dev"
end

desc "Run daemon in foreground (dev mode)"
task :daemon do
  sh "bundle exec ruby bin/redwright daemon run --dev"
end

desc "Run TUI client once against local dev server"
task :tui do
  sh "bundle exec ruby bin/redwright daemon run --dev --ingress tui --once"
end

desc "Run Telegram client once against local dev server"
task :telegram do
  sh "bundle exec ruby bin/redwright daemon run --dev --ingress telegram --once"
end

desc "Run server + telegram adapter + tui client in one command (dev mode)"
task "daemon:all" do
  commands = [
    "bundle exec ruby bin/redwright server run --dev",
    "bundle exec ruby bin/redwright daemon run --dev --ingress telegram",
    "bundle exec ruby bin/redwright daemon run --dev --ingress tui"
  ]
  pids = []

  begin
    pids << Process.spawn(commands[0], out: $stdout, err: $stderr)
    sleep 0.8
    pids << Process.spawn(commands[1], out: $stdout, err: $stderr)
    sleep 0.8
    pids << Process.spawn(commands[2], in: $stdin, out: $stdout, err: $stderr)
    Process.wait(pids[2])
  ensure
    pids.each do |pid|
      begin
        Process.kill("TERM", pid)
      rescue StandardError
        nil
      end
    end
    pids.each do |pid|
      begin
        Process.wait(pid)
      rescue StandardError
        nil
      end
    end
  end
end

desc "Run daemon in foreground (dev mode) with trace banners enabled"
task "daemon:trace" do
  sh "REDWRIGHT_TRACE=1 bundle exec ruby bin/redwright daemon run --dev"
end

namespace :server do
  desc "Run server in foreground (dev mode)"
  task :run do
    sh "bundle exec ruby bin/redwright server run --dev"
  end

  desc "Server status (dev mode)"
  task :status do
    sh "bundle exec ruby bin/redwright server status --dev"
  end

  desc "Server ping (dev mode)"
  task :ping do
    sh "bundle exec ruby bin/redwright server ping --dev"
  end

  namespace :ctl do
    desc "Server ctl status (dev mode)"
    task :status do
      sh "bundle exec ruby bin/redwright server ctl status --dev"
    end

    desc "Server ctl stop (dev mode)"
    task :stop do
      sh "bundle exec ruby bin/redwright server ctl stop --dev"
    end

    desc "Server ctl resume (dev mode)"
    task :resume do
      sh "bundle exec ruby bin/redwright server ctl resume --dev"
    end

    desc "Server ctl trace (dev mode)"
    task :trace do
      sh "bundle exec ruby bin/redwright server ctl trace --dev"
    end
  end
end

desc "Run traced dev cycle with banner output for runtime/sqlite and LLM placeholders"
task "run-trace" do
  project_alias = "rw-trace"
  message = ENV.fetch("MSG", "trace run")
  project_path = Dir.pwd

  sh "REDWRIGHT_TRACE=1 bundle exec ruby bin/redwright bootstrap --dev"
  config_path = File.join(Dir.pwd, "_workspace", ".config", "redwright", "config.yml")
  File.write(config_path, <<~YAML)
    runtime:
      loop_interval_ms: 1000
      blocked_retry_attempts: 1
    telegram:
      bot_token: "trace-dummy-token"
      poll_interval_seconds: 1
      allowed_chat_ids: []
    paths:
      default_projects_root: "~/redwright"
    models:
      coding:
        - provider: "openai"
          name: "gpt-5.2"
      non_coding:
        - provider: "openai"
          name: "gpt-5-mini"
  YAML
  sh "REDWRIGHT_TRACE=1 bundle exec ruby bin/redwright project register --dev --path #{Shellwords.escape(project_path)} --alias #{Shellwords.escape(project_alias)}"

  sh "REDWRIGHT_TRACE=1 bundle exec ruby -e 'require_relative \"lib/redwright/app_config\"; require_relative \"lib/redwright/model_resolver\"; require_relative \"lib/redwright/trace\"; cfg = Redwright::AppConfigLoader.new(mode: :dev).load; resolver = Redwright::ModelResolver.new(cfg.models); model = resolver.resolve(\"non_coding\"); Redwright::Trace.llm_request(role: \"non_coding\", provider: model.provider, model: model.name, action: \"none\", payload_bytes: 0); Redwright::Trace.llm_response(status: \"skipped\", latency_ms: 0, output_bytes: 0, finish_reason: \"llm_not_integrated\")'"

  sh "REDWRIGHT_TRACE=1 bundle exec ruby bin/redwright flow process --dev --project #{Shellwords.escape(project_alias)} --message #{Shellwords.escape(message)} --confirm-new-workstream"
end

desc "Run redwright CLI. Usage: bundle exec rake run CMD='flow process --dev --message \"hi\"'"
task :run do
  cmd = ENV.fetch("CMD", "").strip
  raise ArgumentError, "set CMD='...'" if cmd.empty?

  sh "bundle exec ruby bin/redwright #{cmd}"
end

desc "Smoke run: bootstrap + register cwd project + process one message"
task :smoke do
  alias_name = "rw-smoke"
  message = "smoke check"
  project_path = Dir.pwd

  sh "bundle exec ruby bin/redwright bootstrap --dev"
  sh "bundle exec ruby bin/redwright project register --dev --path #{Shellwords.escape(project_path)} --alias #{Shellwords.escape(alias_name)}"
  sh "bundle exec ruby bin/redwright flow process --dev --project #{Shellwords.escape(alias_name)} --message #{Shellwords.escape(message)} --confirm-new-workstream"
end

namespace :smoke do
  desc "Daemon startup smoke in dev mode (single iteration, no external ingress)"
  task :daemon do
    sh "bundle exec ruby bin/redwright bootstrap --dev"

    config_path = File.join(Dir.pwd, "_workspace", ".config", "redwright", "config.yml")
    File.write(config_path, <<~YAML)
      runtime:
        loop_interval_ms: 1
        blocked_retry_attempts: 1
      telegram:
        bot_token: "dummy-token"
        poll_interval_seconds: 1
        allowed_chat_ids: []
      paths:
        default_projects_root: "~/redwright"
      models:
        coding:
          - provider: "openai"
            name: "gpt-5.2"
        non_coding:
          - provider: "openai"
            name: "gpt-5-mini"
    YAML

    sh "bundle exec ruby bin/redwright daemon run --dev --once --ingress none"
  end
end

namespace :test do
  desc "Run daemon+telegram invariant gate"
  task :invariants do
    sh "bundle exec ruby -Itest test/redwright/daemon_telegram_invariant_test.rb"
  end

  desc "Run runtime line coverage with progress indicator and concise summary"
  task :coverage do
    combined = +""
    status = nil

    Open3.popen3("bundle exec ruby -Itest test/support/coverage_runner.rb") do |_stdin, stdout, stderr, wait_thr|
      heartbeat = Thread.new do
        while wait_thr.alive?
          print "."
          $stdout.flush
          sleep 0.5
        end
      end

      out_thread = Thread.new { stdout.read.to_s }
      err_thread = Thread.new { stderr.read.to_s }

      status = wait_thr.value
      heartbeat.join
      puts

      combined = out_thread.value + "\n" + err_thread.value
    end

    coverage = combined.lines.select { |line| line.match?(/^quality:coverage percent=/) }.last
    finished = combined.lines.select { |line| line.match?(/^Finished in /) }.last
    summary = combined.lines.select { |line| line.match?(/^[0-9]+ runs, [0-9]+ assertions,/) }.last
    puts coverage if coverage
    puts finished if finished
    puts summary if summary

    unless status.success?
      puts combined.lines.last(40).join
    end
    abort("test:coverage failed") unless status.success?
  end

  desc "Run simulated ingress e2e with traces and persistent test workspace for inspection"
  task :simulated_e2e_trace do
    sh "REDWRIGHT_TRACE=1 KEEP_TEST_WORKSPACE=1 bundle exec ruby -Itest test/redwright/simulated_ingress_e2e_test.rb"
  end
end

task "test-invariants": "test:invariants"

task default: :test

namespace :app do
  namespace :run do
    desc "Run full dev stack in foreground (server + web + telegram ingress)"
    task :foreground do
      Redwright::Runtime::ForegroundRunner.run!
    end
  end
end

namespace :quality do
  def quality_helper
    @quality_helper ||= Redwright::LocalQuality.new
  end

  def lint_command
    ENV.fetch("LINT_CMD", "bundle exec ruby -wc lib/redwright.rb")
  end

  def test_command
    ENV.fetch("TEST_CMD", "bundle exec rake test")
  end

  desc "Run local lint quality check and persist artifact"
  task :lint do
    artifact = quality_helper.run_step(name: "lint", command: lint_command)
    quality_helper.write_artifact(path: "tmp/quality/lint-status.json", payload: artifact)
    puts "quality:lint status=#{artifact[:status]} exit_code=#{artifact[:exit_code]}"
    abort("quality:lint failed") unless artifact[:status] == "pass"
  end

  desc "Run local test quality check and persist artifact"
  task :test do
    artifact = quality_helper.run_step(name: "test", command: test_command)
    quality_helper.write_artifact(path: "tmp/quality/test-status.json", payload: artifact)
    puts "quality:test status=#{artifact[:status]} exit_code=#{artifact[:exit_code]}"
    abort("quality:test failed") unless artifact[:status] == "pass"
  end

  desc "Run all local quality checks"
  task :coverage do
    result = Open3.capture3("bundle exec ruby -Itest test/support/coverage_runner.rb")
    stdout, stderr, status = result
    puts stdout unless stdout.to_s.strip.empty?
    warn stderr unless stderr.to_s.strip.empty?
    abort("quality:coverage failed") unless status.success?
  end

  desc "Run all local quality checks"
  task all: %i[lint test coverage] do
    lint = quality_helper.read_artifact(path: "tmp/quality/lint-status.json")
    test = quality_helper.read_artifact(path: "tmp/quality/test-status.json")
    summary = quality_helper.build_summary(lint: lint, test: test)
    quality_helper.write_artifact(path: "tmp/quality/summary.json", payload: summary)
    puts "quality:all status=#{summary[:status]}"
    abort("quality:all failed") unless summary[:status] == "pass"
  end
end

namespace :badges do
  def quality_helper
    @quality_helper ||= Redwright::LocalQuality.new
  end

  def run_quality_task(task_name)
    task = Rake::Task[task_name]
    task.reenable
    task.invoke
    true
  rescue SystemExit
    false
  end

  desc "Build README local badges from tmp/quality artifacts"
  task :build do
    lint = quality_helper.read_artifact(path: "tmp/quality/lint-status.json")
    test = quality_helper.read_artifact(path: "tmp/quality/test-status.json")
    summary = quality_helper.read_artifact(path: "tmp/quality/summary.json")
    coverage = quality_helper.read_artifact(path: "tmp/quality/coverage.json")
    quality_helper.render_readme_badges(
      readme_path: "README.md",
      lint: lint,
      test: test,
      summary: summary,
      coverage: coverage
    )
    puts "badges:build updated README local badge section"
  end

  desc "Run quality checks and refresh README local badges"
  task :refresh do
    lint_ok = run_quality_task("quality:lint")
    test_ok = run_quality_task("quality:test")
    coverage_ok = run_quality_task("quality:coverage")

    lint = quality_helper.read_artifact(path: "tmp/quality/lint-status.json")
    test = quality_helper.read_artifact(path: "tmp/quality/test-status.json")
    summary = quality_helper.build_summary(lint: lint, test: test)
    quality_helper.write_artifact(path: "tmp/quality/summary.json", payload: summary)

    Rake::Task["badges:build"].reenable
    Rake::Task["badges:build"].invoke

    abort("badges:refresh failed") unless lint_ok && test_ok && coverage_ok
  end
end

namespace :pr do
  namespace :dev_to_main do
    desc "Poor-man local CI gate for dev->main PRs (tests + badge freshness)"
    task :gate do
      sh "bundle exec rake badges:refresh"

      tracked_badge_targets = "README.md badges"
      diff_output, = Open3.capture2("git diff --name-only -- #{tracked_badge_targets}")
      changed_targets = diff_output.lines.map(&:strip).reject(&:empty?)
      next if changed_targets.empty?

      puts "pr:dev_to_main:gate detected stale tracked badge targets:"
      changed_targets.each { |path| puts "  - #{path}" }
      abort("Commit refreshed badge outputs before opening PR dev->main.")
    end
  end
end
