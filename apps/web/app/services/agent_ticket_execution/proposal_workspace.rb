require "find"

module AgentTicketExecution
  class ProposalWorkspace
    MAX_FILES = 4096
    MAX_BYTES = 64 * 1024 * 1024

    def initialize(path)
      @root = File.expand_path(path)
      unless File.directory?(@root) && File.realpath(@root) == @root
        raise Harnesses::Error.new("Ticket workspace must be a real directory.", code: :invalid_workspace)
      end
    end

    def synchronize
      directory = ENV.fetch("REDWRIGHT_HARNESS_STATE") { File.join(Dir.home, ".local/state/redwright/harness-operations") }
      FileUtils.mkdir_p(directory, mode: 0o700)
      stat = File.lstat(directory)
      unless stat.directory? && !stat.symlink? && stat.uid == Process.uid && (stat.mode & 0o077).zero?
        raise Harnesses::Error.new("The harness state directory must be private.", code: :unavailable)
      end
      path = File.join(directory, "workspace-#{Digest::SHA256.hexdigest(@root)}.lock")
      File.open(path, File::RDWR | File::CREAT | File::NOFOLLOW, 0o600) do |file|
        stat = file.stat
        unless stat.file? && stat.uid == Process.uid && (stat.mode & 0o077).zero? && file.flock(File::LOCK_EX | File::LOCK_NB)
          raise Harnesses::Error.new("Another owned ticket operation holds this workspace.", code: :conflict)
        end
        yield
      ensure
        file.flock(File::LOCK_UN) if file
      end
    rescue Errno::ELOOP, Errno::EACCES
      raise Harnesses::Error.new("The owned workspace lock is unavailable.", code: :unavailable)
    end

    def snapshot
      entries = {}
      bytes = 0
      count = 0
      Find.find(@root) do |path|
        next if path == @root
        relative = path.delete_prefix(@root + "/")
        Find.prune if relative == ".git"
        stat = File.lstat(path)
        count += 1
        if relative.bytesize > 1024 || count > MAX_FILES || (!stat.directory? && (bytes += stat.size) > MAX_BYTES)
          raise Harnesses::Error.new("Ticket workspace exceeds 4,096 entries or 64 MiB.", code: :workspace_too_large)
        end
        next if stat.directory?
        value = if stat.symlink?
          ["link", File.readlink(path)]
        elsif stat.file?
          ["file", stat.mode & 0o777, file_digest(path, stat)]
        else
          raise Harnesses::Error.new("Ticket workspace contains an unsupported file type.", code: :invalid_workspace)
        end
        current = File.lstat(path)
        unless [stat.ino, stat.size, stat.mtime, stat.ctime] == [current.ino, current.size, current.mtime, current.ctime]
          raise Harnesses::Error.new("Ticket workspace changed during capture.", code: :base_conflict)
        end
        entries[relative] = value
      end
      {"version" => "ticket-base/v1", "head" => git("rev-parse", "HEAD").strip,
        "index_digest" => Digest::SHA256.hexdigest(git("ls-files", "--stage", "-z")),
        "files_digest" => Harnesses::CanonicalJson.digest(entries), "file_count" => entries.size}
    rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
      raise Harnesses::Error.new("Ticket workspace changed or became unavailable.", code: :base_conflict)
    end

    def verify!(expected)
      unless snapshot == expected
        raise Harnesses::Error.new("Ticket workspace changed outside the owned operation; regenerate against the new base.", code: :base_conflict)
      end
    end

    def validate!(payload)
      Array(payload["files"]).each do |file|
        raise ArgumentError unless file.is_a?(Hash) && file["path"].is_a?(String) &&
          (file["content"].is_a?(String) ^ file["patch"].is_a?(String))
        validate_path!(file.fetch("path"))
        validate_patch!(file.fetch("patch")) if file.key?("patch")
      end
      Array(payload["commands"]).each do |command|
        raise ArgumentError unless command.is_a?(Hash) && command["command"].is_a?(String) && command["command"].present?
      end
      Array(payload["actions"]).each do |action|
        raise ArgumentError unless action.is_a?(Hash) && OutputApplier::ALLOWED_DIRECT_ACTION_TYPES.include?(action["type"]) && action["args"].is_a?(Hash)
        args = action.fetch("args")
        case action.fetch("type")
        when "write_file"
          raise ArgumentError unless args["content"].is_a?(String)
          validate_path!(args.fetch("path"))
        when "read_file", "list_files", "search"
          validate_path!(args["path"] || ".", allow_root: true)
        when "apply_patch" then validate_patch!(args.fetch("patch"))
        when "run" then raise ArgumentError unless args["command"].is_a?(String) && args["command"].present?
        end
      end
      Array(payload["affected_files"]).each { |path| validate_path!(path) }
    rescue ArgumentError, KeyError, TypeError
      raise Harnesses::Error.new("Ticket proposal contains invalid actions or unsafe paths.", code: :invalid_proposal)
    end

    private

    def file_digest(path, expected)
      File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
        raise Errno::ENOENT unless file.stat.ino == expected.ino && file.stat.file?
        digest = Digest::SHA256.new
        read = 0
        while (chunk = file.read(64 * 1024))
          read += chunk.bytesize
          raise Errno::ENOENT if read > expected.size
          digest.update(chunk)
        end
        digest.hexdigest
      end
    end

    def validate_path!(path, allow_root: false)
      raise ArgumentError unless path.is_a?(String) && path.bytesize.between?(1, 1024) && !path.include?("\0")
      return if allow_root && path == "."
      parts = path.split("/", -1)
      raise ArgumentError if Pathname.new(path).absolute? || parts.any? { |part| ["", ".", "..", ".git"].include?(part) }
      parts.each_index do |index|
        raise ArgumentError if File.symlink?(File.join(@root, *parts[0..index]))
      end
    end

    def validate_patch!(patch)
      raise ArgumentError unless patch.is_a?(String) && patch.start_with?("*** Begin Patch\n") && patch.lines.last&.strip == "*** End Patch"
      paths = patch.scan(/^\*\*\* (?:Add File|Update File|Delete File|Move to): (.+)$/).flatten
      raise ArgumentError if paths.empty?
      paths.each { |path| validate_path!(path) }
    end

    def git(*args)
      outcome = Harnesses::ProcessSupervisor.new(stdout_limit: 256 * 1024, stderr_limit: 16 * 1024).run(
        command: ["git", *args], workspace: @root, deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5,
        capture_stdout: 256 * 1024)
      raise Harnesses::Error.new("Ticket workspace Git base is unavailable.", code: :invalid_workspace) unless outcome.status.success?
      outcome.stdout
    end
  end
end
