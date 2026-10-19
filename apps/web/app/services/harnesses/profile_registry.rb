module Harnesses
  class ProfileRegistry
    PUBLIC_FIELDS = %w[name harness protocol_revision requested_provider requested_model thinking capabilities model_config_revision].freeze
    PRIVATE_FIELDS = %w[executable_ref credential_ref model_config_ref].freeze
    Profile = Data.define(:public_values, :private_values) do
      def ready!
        unless public_values.fetch("capabilities", {})["structured_output"] == true
          raise Error.new("The prepared profile lacks structured output capability.", code: :unsupported_capability)
        end
        if public_values.fetch("harness") == "pi"
          raise Error.new("Pi requires a verified containment policy before selection.", code: :unsupported_capability)
        end
        self
      end
    end

    def initialize(path: ENV.fetch("REDWRIGHT_HARNESS_PROFILES") { File.join(Dir.home, ".config/redwright/harnesses.json") })
      @path = File.expand_path(path)
    end

    def resolve(name)
      resolve_many([name]).fetch(name)
    end

    def resolve_many(names)
      profiles = load_profiles
      names.uniq.to_h do |name|
        row = profiles.find { |item| item["name"] == name }
        raise Error.new("Unknown prepared harness profile. Configure it locally before selecting it.", code: :unknown_profile) unless row
        [name, resolve_profile(row)]
      end
    end

    def public_profiles
      load_profiles.map { |row| resolve_profile(row).public_values }
    end

    private

    def load_profiles
      File.open(@path, File::RDONLY | File::NOFOLLOW) do |file|
        stat = file.stat
        root = Rails.root.join("../..").cleanpath.to_s + File::SEPARATOR
        unless stat.file? && stat.uid == Process.uid && (stat.mode & 0o077).zero? && stat.size <= 64 * 1024 &&
            !File.realpath(@path).start_with?(root)
          raise Error.new("Harness profiles require a private regular file outside the repository, at most 64 KiB.", code: :invalid_profile)
        end
        bytes = file.read(64 * 1024 + 1)
        raise Error.new("The harness profile file is too large.", code: :invalid_profile) if bytes.bytesize > 64 * 1024
        value = JSON.parse(bytes)
        rows = value["profiles"] if value.is_a?(Hash)
        unless value.is_a?(Hash) && value.keys.sort == %w[profiles version] && value["version"] == 1 &&
            rows.is_a?(Array) && rows.size <= 64 && rows.all? { |row| valid_profile?(row) } &&
            rows.map { |row| row["name"] }.uniq.size == rows.size
          raise Error.new("The harness profile file has an invalid format.", code: :invalid_profile)
        end
        rows
      end
    rescue Errno::ENOENT
      []
    rescue JSON::ParserError, Errno::EACCES, Errno::ELOOP
      raise Error.new("The harness profile file is unavailable or invalid.", code: :invalid_profile)
    end

    def valid_profile?(row)
      row.is_a?(Hash) && (row.keys - PUBLIC_FIELDS - PRIVATE_FIELDS).empty? &&
        row["name"].is_a?(String) && ProjectHarnessSetting::PROFILE_KEY.match?(row["name"]) &&
        %w[codex pi].include?(row["harness"]) && row["executable_ref"].is_a?(String) &&
        (PUBLIC_FIELDS - ["capabilities"]).all? { |field| row[field].nil? || (row[field].is_a?(String) && row[field].bytesize.between?(1, 128)) } &&
        row.fetch("capabilities", {}).is_a?(Hash) &&
        row.fetch("capabilities", {}).all? { |key, value| %w[structured_output os_read_only_containment controlled_inspection measured_usage].include?(key) && [true, false].include?(value) } &&
        PRIVATE_FIELDS.all? { |field| row[field].nil? || (row[field].is_a?(String) && row[field].bytesize.between?(1, 4096) && row[field].start_with?("/")) }
    end

    def resolve_profile(row)
      program = row.fetch("executable_ref")
      unless File.file?(program) && File.executable?(program)
        raise Error.new("The prepared harness executable is unavailable.", code: :unavailable)
      end
      if row["harness"] == "pi" && (row["protocol_revision"] != "1.3.0" || row["requested_provider"].blank? || row["requested_model"].blank?)
        raise Error.new("Pi profiles require protocol 1.3.0 and an explicit provider and model.", code: :invalid_profile)
      end
      if row["harness"] == "codex" && ![nil, "codex-exec/v1"].include?(row["protocol_revision"])
        raise Error.new("Unsupported Codex profile protocol.", code: :invalid_profile)
      end
      row.slice("credential_ref", "model_config_ref").each_value do |path|
        next if path.nil?
        stat = File.lstat(path)
        unless stat.file? && !stat.symlink? && stat.uid == Process.uid && (stat.mode & 0o077).zero?
          raise Error.new("Prepared harness resources must be private regular files.", code: :invalid_profile)
        end
      end
      values = {"requested_provider" => nil, "requested_model" => nil, "capabilities" => {}}.merge(row.slice(*PUBLIC_FIELDS))
      values["protocol_revision"] ||= "codex-exec/v1"
      stat = File.stat(program)
      values["executable_identity"] = CanonicalJson.digest([File.realpath(program), stat.dev, stat.ino, stat.size, stat.mtime.to_r.to_s])
      values["revision"] = CanonicalJson.digest(values)
      Profile.new(public_values: JSON.parse(CanonicalJson.dump(values), freeze: true),
        private_values: JSON.parse(CanonicalJson.dump(row.slice(*PRIVATE_FIELDS)), freeze: true))
    rescue Errno::ENOENT, Errno::EACCES
      raise Error.new("A prepared harness resource is unavailable.", code: :unavailable)
    end
  end
end
