# frozen_string_literal: true

require "fileutils"
require "bundler"
require "socket"

module Redwright
  module Runtime
    class ForegroundRunner
      def self.run!
        new.run!
      end

      def run!
        prepare_paths
        clear_stale_process_state

        start_server
        prepare_web_database_and_users
        start_web
        wait_for_web_port
        wait_for_server_socket
        print_runtime_banner
        start_telegram_foreground
      ensure
        stop_processes
      end

      private

      attr_reader :root_dir, :log_dir, :state_dir, :web_dir, :web_port, :socket_file, :web_pid_file
      attr_reader :owner_email, :owner_password, :agent_coder_email, :agent_coder_password
      attr_reader :agent_reviewer_email, :agent_reviewer_password, :agent_merger_email, :agent_merger_password
      attr_reader :server_log, :web_log

      def prepare_paths
        @root_dir = Dir.pwd
        @log_dir = File.join(root_dir, "tmp", "logs")
        @state_dir = File.join(root_dir, "_workspace", "redwright")
        @web_dir = File.join(root_dir, "apps", "web")
        @web_port = ENV.fetch("WEB_PORT", "3000")
        @socket_file = File.join(state_dir, "rw.sock")
        @web_pid_file = File.join(web_dir, "tmp", "pids", "server.pid")
        @server_log = File.join(log_dir, "server.live.log")
        @web_log = File.join(log_dir, "web.live.log")

        @owner_email = ENV.fetch("OWNER_EMAIL", "adrian@redwright.local")
        @owner_password = ENV.fetch("OWNER_PASSWORD", "changeme-owner")
        @agent_coder_email = ENV.fetch("AGENT_CODER_EMAIL", "agent-coder@redwright.local")
        @agent_coder_password = ENV.fetch("AGENT_CODER_PASSWORD", "changeme-agent-coder")
        @agent_reviewer_email = ENV.fetch("AGENT_REVIEWER_EMAIL", "agent-reviewer@redwright.local")
        @agent_reviewer_password = ENV.fetch("AGENT_REVIEWER_PASSWORD", "changeme-agent-reviewer")
        @agent_merger_email = ENV.fetch("AGENT_MERGER_EMAIL", "agent-merger@redwright.local")
        @agent_merger_password = ENV.fetch("AGENT_MERGER_PASSWORD", "changeme-agent-merger")

        FileUtils.mkdir_p(log_dir)
        FileUtils.mkdir_p(state_dir)
      end

      def clear_stale_process_state
        clear_stale_runtime_lock
        if File.exist?(web_pid_file)
          stale_web_pid = File.read(web_pid_file).to_i
          safe_kill(stale_web_pid, "TERM") if stale_web_pid.positive?
          FileUtils.rm_f(web_pid_file)
        end
        FileUtils.rm_f(socket_file)
      end

      def start_server
        puts "Starting server (dev)..."
        @server_pid = Process.spawn("bundle exec ruby bin/redwright server run --dev", out: server_log, err: server_log)
      end

      def prepare_web_database_and_users
        puts "Preparing Rails app database and seed users..."
        ensure_web_bundle_ready
        web_system!("bundle exec bin/rails dartsass:build")
        web_system!("bundle exec bin/rails db:prepare")
        web_system!(
            <<~CMD
              OWNER_EMAIL=#{shell(owner_email)} \
              OWNER_PASSWORD=#{shell(owner_password)} \
              AGENT_CODER_EMAIL=#{shell(agent_coder_email)} \
              AGENT_CODER_PASSWORD=#{shell(agent_coder_password)} \
              AGENT_REVIEWER_EMAIL=#{shell(agent_reviewer_email)} \
              AGENT_REVIEWER_PASSWORD=#{shell(agent_reviewer_password)} \
              AGENT_MERGER_EMAIL=#{shell(agent_merger_email)} \
              AGENT_MERGER_PASSWORD=#{shell(agent_merger_password)} \
              bundle exec bin/rails runner '
                users = [
                  { email: ENV.fetch("OWNER_EMAIL"), password: ENV.fetch("OWNER_PASSWORD") },
                  { email: ENV.fetch("AGENT_CODER_EMAIL"), password: ENV.fetch("AGENT_CODER_PASSWORD") },
                  { email: ENV.fetch("AGENT_REVIEWER_EMAIL"), password: ENV.fetch("AGENT_REVIEWER_PASSWORD") },
                  { email: ENV.fetch("AGENT_MERGER_EMAIL"), password: ENV.fetch("AGENT_MERGER_PASSWORD") }
                ]
                users.each do |attrs|
                  user = User.find_or_initialize_by(email_address: attrs[:email])
                  user.password = attrs[:password]
                  user.password_confirmation = attrs[:password]
                  user.save!
                end
                puts("seeded_users=\#{users.map { |u| u[:email] }.join(",")}")
              '
            CMD
        )
      end

      def start_web
        puts "Starting Rails app on port #{web_port}..."
        Bundler.with_unbundled_env do
          @web_pid = Process.spawn(
            web_unbundled_env,
            "bundle exec bin/rails server -b 127.0.0.1 -p #{web_port}",
            chdir: web_dir,
            out: web_log,
            err: web_log
          )
        end
      end

      def wait_for_web_port
        240.times do
          return if tcp_port_open?("127.0.0.1", web_port.to_i)
          raise "Rails app died during startup. Check #{web_log}\n#{tail_web_log}" unless process_alive?(@web_pid)

          sleep 0.25
        end
        raise "Rails app not ready: http://127.0.0.1:#{web_port}\n#{tail_web_log}"
      end

      def wait_for_server_socket
        240.times do
          return if File.socket?(socket_file)
          raise "Server died during startup. Check #{server_log}" unless process_alive?(@server_pid)

          sleep 0.25
        end
        raise "Server socket not ready: #{socket_file}\n#{tail_server_log}"
      end

      def print_runtime_banner
        puts "Server log: #{server_log}"
        puts "Web log: #{web_log}"
        puts "Web URL: http://127.0.0.1:#{web_port}"
        puts "Owner user: #{owner_email}"
        puts "Agent users: #{agent_coder_email}, #{agent_reviewer_email}, #{agent_merger_email}"
      end

      def start_telegram_foreground
        puts "Starting telegram adapter (dev, foreground)..."
        puts "Press Ctrl+C to stop all processes."
        Signal.trap("INT") { stop_processes; exit(130) }
        Signal.trap("TERM") { stop_processes; exit(143) }
        @telegram_pid = Process.spawn(
          {
            "REDWRIGHT_TRACE" => "1",
            "REDWRIGHT_RAILS_API_URL" => "http://127.0.0.1:#{web_port}/api/v1"
          },
          "bundle exec ruby bin/redwright daemon run --dev --ingress telegram"
        )
        Process.wait(@telegram_pid)
      end

      def stop_processes
        [@telegram_pid, @server_pid, @web_pid].compact.each { |pid| safe_kill(pid, "TERM") }
      end

      def process_alive?(pid)
        Process.kill(0, pid)
        true
      rescue StandardError
        false
      end

      def safe_kill(pid, signal)
        Process.kill(signal, pid)
      rescue StandardError
        nil
      end

      def tcp_port_open?(host, port)
        socket = TCPSocket.new(host, port)
        socket.close
        true
      rescue StandardError
        false
      end

      def system!(*args)
        success = system(*args)
        raise "Command failed" unless success
      end

      def shell(value)
        "'" + value.to_s.gsub("'", %q('\\'')) + "'"
      end

      def web_bundle_env
        {
          "BUNDLE_GEMFILE" => File.join(web_dir, "Gemfile")
        }
      end

      def ensure_web_bundle_ready
        lockfile = File.join(web_dir, "Gemfile.lock")
        return unless File.file?(lockfile)

        platform = Gem::Platform.local.to_s
        lock_content = File.read(lockfile)

        unless lock_content.include?(platform)
          puts "Adding missing bundle platform to apps/web lockfile: #{platform}"
          web_system!("bundle lock --add-platform #{shell_arg(platform)}")
        end

        web_system!("bundle install")
      end

      def shell_arg(value)
        value.to_s.gsub(/[^a-zA-Z0-9._:-]/, "")
      end

      def web_system!(cmd)
        Bundler.with_unbundled_env do
          Dir.chdir(web_dir) do
            system!(web_unbundled_env, cmd)
          end
        end
      end

      def web_unbundled_env
        {
          "BUNDLE_GEMFILE" => File.join(web_dir, "Gemfile")
        }
      end

      def clear_stale_runtime_lock
        lock_file = File.join(state_dir, "runtime.lock")
        return unless File.file?(lock_file)

        begin
          lock_content = File.read(lock_file)
          lock_pid = lock_content[/\"pid\"\s*:\s*(\d+)/, 1].to_i
          safe_kill(lock_pid, "TERM") if lock_pid.positive?
        rescue StandardError
          nil
        end
        FileUtils.rm_f(lock_file)
      end

      def tail_server_log
        return "Server log not found." unless File.file?(server_log)

        lines = File.readlines(server_log).last(40)
        "Server log tail:\n#{lines.join}"
      rescue StandardError
        "Unable to read server log tail."
      end

      def tail_web_log
        return "Web log not found." unless File.file?(web_log)

        lines = File.readlines(web_log).last(40)
        "Web log tail:\n#{lines.join}"
      rescue StandardError
        "Unable to read web log tail."
      end
    end
  end
end
