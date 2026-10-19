require "fileutils"
require "securerandom"

module Harnesses
  class BindingStore
    def initialize(directory: ENV.fetch("REDWRIGHT_HARNESS_STATE") { File.join(Dir.home, ".local/state/redwright/harness-operations") })
      @directory = File.expand_path(directory)
    end

    def write(value)
      bytes = CanonicalJson.dump({"version" => 1, "resources" => value})
      raise Error.new("The private harness binding is too large.", code: :invalid_profile) if bytes.bytesize > 16 * 1024
      FileUtils.mkdir_p(@directory, mode: 0o700)
      stat = File.lstat(@directory)
      unless stat.directory? && !stat.symlink? && stat.uid == Process.uid && (stat.mode & 0o077).zero?
        raise Error.new("The harness state directory must be private.", code: :unavailable)
      end
      reference = SecureRandom.uuid
      File.open(path(reference), File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
        file.write(bytes)
        file.flush
        file.fsync
      end
      reference
    end

    def read(reference)
      File.open(path(reference), File::RDONLY | File::NOFOLLOW) do |file|
        stat = file.stat
        unless stat.file? && stat.uid == Process.uid && (stat.mode & 0o077).zero? && stat.size <= 16 * 1024
          raise Error.new("The retained harness binding is unavailable.", code: :unavailable)
        end
        bytes = file.read(16 * 1024 + 1)
        raise Error.new("The retained harness binding is too large.", code: :invalid_binding) if bytes.bytesize > 16 * 1024
        value = JSON.parse(bytes, freeze: true)
        unless value.is_a?(Hash) && value.keys.sort == %w[resources version] && value["version"] == 1 && value["resources"].is_a?(Hash)
          raise Error.new("Unsupported retained harness binding.", code: :invalid_binding)
        end
        value.fetch("resources")
      end
    rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP, JSON::ParserError
      raise Error.new("The retained harness binding is unavailable.", code: :unavailable)
    end

    def delete(reference)
      File.unlink(path(reference))
    rescue Errno::ENOENT
      nil
    end

    private

    def path(reference)
      unless /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/.match?(reference.to_s)
        raise Error.new("Invalid private harness reference.", code: :invalid_binding)
      end
      File.join(@directory, "#{reference}.json")
    end
  end
end
