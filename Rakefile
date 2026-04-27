# frozen_string_literal: true

require "shellwords"

desc "Run full test suite"
task :test do
  sh 'bundle exec ruby -Itest -e \'Dir["test/**/*_test.rb"].sort.each { |path| require File.expand_path(path) }\''
end

desc "Bootstrap runtime paths and sqlite in --dev mode"
task :bootstrap do
  sh "bundle exec ruby bin/redwright bootstrap --dev"
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
        default_projects_root: "#{Dir.pwd}/_workspace/redwright"
    YAML

    sh "bundle exec ruby bin/redwright daemon run --dev --once --ingress none"
  end
end

namespace :test do
  desc "Run daemon+telegram invariant gate"
  task :invariants do
    sh "bundle exec ruby -Itest test/redwright/daemon_telegram_invariant_test.rb"
  end
end

task "test-invariants": "test:invariants"

task default: :test
