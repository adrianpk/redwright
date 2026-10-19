require "tmpdir"
require "fileutils"

module Harnesses
  class LinuxSandbox
    POLICY_REVISION = "pi-linux-bwrap/v1".freeze
    LIBRARIES = %w[libc.so.6 libpthread.so.0 libdl.so.2 libm.so.6 libgcc_s.so.1 libstdc++.so.6 libresolv.so.2 libnss_dns.so.2 libnss_files.so.2 libreadline.so.8 libncursesw.so.6 libtinfo.so.6].freeze
    LIBRARY_DIRECTORIES = %w[/usr/lib/x86_64-linux-gnu /lib/x86_64-linux-gnu /usr/lib /lib].freeze
    BASE_ENV = {"PATH" => "/nonexistent", "HOME" => "/scratch/home", "TMPDIR" => "/scratch/tmp",
      "XDG_CONFIG_HOME" => "/scratch/config", "XDG_CACHE_HOME" => "/scratch/cache",
      "PI_CODING_AGENT_DIR" => "/scratch/agent", "LD_LIBRARY_PATH" => "/runtime/lib",
      "SSL_CERT_FILE" => "/etc/ssl/cert.pem", "LANG" => "C.UTF-8"}.freeze

    class Context
      attr_reader :scratch, :environment

      def initialize(prefix:, program:, scratch:, workspace:)
        @prefix, @program, @scratch, @source_workspace = prefix, program, scratch, workspace
        @environment = BASE_ENV.dup.freeze
        @verified = false
      end

      def workspace = @scratch
      def policy_revision = POLICY_REVISION
      def verified? = @verified

      def command_for(command)
        unless verified? && File.realpath(command.first) == @program
          raise Error.new("The executable is outside the verified containment context.", code: :unsupported_capability)
        end
        @prefix + ["--", "/opt/harness/program", *command.drop(1)]
      end

      def verify!(request)
        # Probe the same mounts and namespace policy before admitting the model executable.
        marker = ".redwright-containment-#{SecureRandom.hex(12)}"
        source = 'set -eu; printf verified > /scratch/probe; if (: > "$1") 2>/dev/null; then exit 7; fi; if (: > /etc/hosts) 2>/dev/null; then exit 8; fi; printf verified'
        result = ProcessSupervisor.new(stdout_limit: 1024, stderr_limit: 4096).run(
          command: @prefix[0...-2] + ["--ro-bind", File.realpath("/bin/sh"), "/opt/check", *@prefix.last(2), "--", "/opt/check", "-c", source, "probe", "/workspace/#{marker}"],
          workspace: @scratch, env: environment, unsetenv_others: true, capture_stdout: 1024,
          deadline: [request.deadline, Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5].min, cancellation: request.cancellation)
        unless result.status.success? && result.stdout == "verified" && File.read(File.join(@scratch, "probe")) == "verified"
          raise Error.new("The Linux containment policy could not be verified.", code: :containment_unavailable)
        end
        @verified = true
      ensure
        # Only this fresh marker can be removed if an incorrectly constructed policy allowed the probe write.
        File.unlink(File.join(@source_workspace, marker)) if marker && File.file?(File.join(@source_workspace, marker))
      end
    end

    def self.ready!(program:, platform: RUBY_PLATFORM, bwrap: nil)
      unless platform.include?("linux") && platform.include?("x86_64")
        raise Error.new("Pi containment supports Linux x86_64 native executables only.", code: :unsupported_platform)
      end
      executable = File.realpath(program)
      unless File.file?(executable) && File.executable?(executable) && File.binread(executable, 4) == "\x7fELF".b
        raise Error.new("Pi containment requires a prepared native ELF executable; launchers are unsupported.", code: :unsupported_executable)
      end
      tool = bwrap || %w[/usr/bin/bwrap /usr/sbin/bwrap /bin/bwrap].find { |path| File.executable?(path) }
      unless tool && File.file?(tool) && File.executable?(tool)
        raise Error.new("Bubblewrap is unavailable for the Linux containment policy.", code: :containment_unavailable)
      end
      {program: executable, bwrap: File.realpath(tool)}
    rescue Errno::ENOENT, Errno::EACCES
      raise Error.new("The prepared native executable is unavailable.", code: :unavailable)
    end

    def initialize(platform: RUBY_PLATFORM, bwrap: nil)
      @platform, @bwrap = platform, bwrap
    end

    def with_context(request)
      layout = self.class.ready!(program: request.program, platform: @platform, bwrap: @bwrap)
      workspace = File.realpath(request.workspace)
      unless File.directory?(workspace) && !["/", "/home", Dir.home, "/run", "/var", "/usr", "/etc"].include?(workspace)
        raise Error.new("A bounded project workspace is required for containment.", code: :unsupported_capability)
      end
      scratch = Dir.mktmpdir("redwright-pi-", "/tmp")
      %w[home tmp config cache agent work].each { |name| Dir.mkdir(File.join(scratch, name), 0o700) }
      prepare_resources(request, scratch)
      prefix = mount_command(layout, workspace, scratch)
      context = Context.new(prefix: prefix.freeze, program: layout.fetch(:program), scratch: scratch, workspace: workspace)
      context.verify!(request)
      yield context
    ensure
      FileUtils.remove_entry_secure(scratch) if scratch && File.directory?(scratch)
    end

    private

    def prepare_resources(_request, _scratch)
      # Selected resources are prepared by PiResources before the context is admitted.
    end

    def mount_command(layout, workspace, scratch)
      command = [layout.fetch(:bwrap), "--unshare-user", "--unshare-pid", "--unshare-ipc", "--unshare-uts",
        "--new-session", "--die-with-parent", "--disable-userns", "--cap-drop", "ALL", "--clearenv"]
      BASE_ENV.each { |key, value| command += ["--setenv", key, value] }
      LIBRARIES.each do |name|
        source = LIBRARY_DIRECTORIES.map { |directory| File.join(directory, name) }.find { |path| File.file?(path) }
        command += ["--ro-bind", File.realpath(source), "/runtime/lib/#{name}"] if source
      end
      loader = "/lib64/ld-linux-x86-64.so.2"
      raise Error.new("The native executable loader is unavailable.", code: :unsupported_executable) unless File.file?(loader)
      command += ["--ro-bind", File.realpath(loader), loader, "--ro-bind", layout.fetch(:program), "/opt/harness/program"]
      package = File.join(File.dirname(layout.fetch(:program)), "package.json")
      command += ["--ro-bind", File.realpath(package), "/opt/harness/package.json"] if File.file?(package)
      %w[hosts resolv.conf nsswitch.conf].each do |name|
        path = "/etc/#{name}"
        command += ["--ro-bind", File.realpath(path), path] if File.file?(path)
      end
      certificate = %w[/etc/ssl/cert.pem /etc/ssl/certs/ca-certificates.crt].find { |path| File.file?(path) }
      command += ["--ro-bind", File.realpath(certificate), "/etc/ssl/cert.pem"] if certificate
      command + ["--ro-bind", workspace, "/workspace", "--bind", scratch, "/scratch",
        "--symlink", "scratch/tmp", "/tmp", "--proc", "/proc", "--dev", "/dev",
        "--remount-ro", "/proc", "--remount-ro", "/dev", "--chdir", "/scratch/work", "--remount-ro", "/"]
    end
  end
end
