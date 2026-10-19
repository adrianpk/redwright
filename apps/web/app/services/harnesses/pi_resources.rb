require "uri"

module Harnesses
  class PiResources
    MAX_BYTES = 64 * 1024
    APIS = %w[openai-completions openai-responses anthropic-messages google-generative-ai].freeze
    MODEL_FIELDS = %w[id name reasoning input cost contextWindow maxTokens compat].freeze
    SETTINGS = {"defaultTools" => [], "defaultProjectTrust" => "never", "compaction" => {"enabled" => false},
      "retry" => {"enabled" => false}, "cacheWarming" => "off", "packages" => [], "extensions" => [],
      "skills" => [], "prompts" => [], "themes" => []}.freeze

    class << self
      def binary_metadata!(program)
        path = File.join(File.dirname(File.realpath(program)), "package.json")
        unless File.file?(path) && File.size(path) <= MAX_BYTES
          raise Error.new("Pi containment requires the native distribution package metadata.", code: :unsupported_executable)
        end
        value = JSON.parse(File.read(path, MAX_BYTES + 1))
        unless value.is_a?(Hash) && value["name"] == "@earendil-works/pi-coding-agent" &&
            value["version"] == PiAdapter::VERSION && [nil, "pi"].include?(value.dig("piConfig", "name")) &&
            [nil, ".pi"].include?(value.dig("piConfig", "configDir"))
          raise Error.new("Pi containment requires the native 1.3.0 distribution.", code: :unsupported_version)
        end
      rescue Errno::ENOENT, Errno::EACCES, JSON::ParserError, TypeError
        raise Error.new("The prepared Pi package metadata is unavailable or invalid.", code: :unsupported_executable)
      end

      def ready!(binding:, resources:)
        provider = binding.fetch("requested_provider")
        model = binding.fetch("requested_model")
        unless provider.is_a?(String) && model.is_a?(String)
          raise Error.new("An exact Pi provider and model are required.", code: :invalid_binding)
        end
        resource_stat!(resources["credential_ref"])
        snapshot = model_snapshot(resources["model_config_ref"], provider: provider, model: model)
        revision = snapshot && CanonicalJson.digest(snapshot)
        if binding["model_config_revision"] && binding["model_config_revision"] != revision
          raise Error.new("The prepared Pi model configuration changed.", code: :invalid_binding)
        end
        revision
      rescue KeyError
        raise Error.new("The retained Pi resource selection is incomplete.", code: :invalid_binding)
      end

      def prepare!(request, scratch)
        ready!(binding: request.binding, resources: request.resources)
        request.resources.slice("credential_ref", "model_config_ref").each_value do |path|
          if path && File.realpath(path).start_with?(File.realpath(request.workspace) + File::SEPARATOR)
            raise Error.new("Pi resources must be prepared outside the project workspace.", code: :invalid_resource)
          end
        end
        provider = request.binding.fetch("requested_provider")
        auth = read_resource(request.resources.fetch("credential_ref"))
        row = auth[provider] if auth.is_a?(Hash)
        unless row.is_a?(Hash) && row.keys.sort == %w[key type] && row["type"] == "api_key" &&
            row["key"].is_a?(String) && row["key"].bytesize.between?(1, 16 * 1024) && static_value?(row["key"])
          raise Error.new("Pi requires a selected static API key; OAuth, environment expansion and credential commands are unsupported.", code: :unsupported_auth)
        end
        models = model_snapshot(request.resources["model_config_ref"], provider: provider, model: request.binding.fetch("requested_model"))
        if (models && CanonicalJson.digest(models)) != request.binding["model_config_revision"]
          raise Error.new("The retained Pi model configuration changed.", code: :invalid_binding)
        end
        write_snapshot(scratch, "auth.json", {provider => row})
        write_snapshot(scratch, "models.json", models || {"providers" => {}})
        write_snapshot(scratch, "settings.json", SETTINGS)
      end

      def model_snapshot(path, provider:, model:)
        return if path.nil?
        value = read_resource(path)
        unless value.is_a?(Hash) && (value.keys - %w[$schema providers]).empty? && value["providers"].is_a?(Hash)
          invalid_model!
        end
        entry = value["providers"][provider]
        unless entry.is_a?(Hash) && (entry.keys - %w[baseUrl api authHeader models]).empty? &&
            APIS.include?(entry["api"]) && [nil, true, false].include?(entry["authHeader"]) && entry["models"].is_a?(Array)
          invalid_model!
        end
        url = URI.parse(entry.fetch("baseUrl"))
        invalid_model! unless %w[http https].include?(url.scheme) && url.host && !url.userinfo && !url.fragment && static_value?(url.to_s)
        candidates = entry["models"].select { |row| row.is_a?(Hash) && row["id"] == model }
        invalid_model! unless candidates.size == 1
        selected = candidates.first
        invalid_model! unless (selected.keys - MODEL_FIELDS).empty? && valid_model?(selected)
        {"providers" => {provider => entry.except("models").merge("models" => [selected])}}
      rescue URI::InvalidURIError, KeyError, TypeError
        invalid_model!
      end

      private

      def resource_stat!(path)
        unless path.is_a?(String) && path.start_with?("/")
          raise Error.new("A private selected Pi resource is required.", code: :unavailable_resource)
        end
        stat = File.lstat(path)
        repository = Rails.root.join("../..").cleanpath.to_s + File::SEPARATOR
        unless stat.file? && !stat.symlink? && stat.uid == Process.uid && (stat.mode & 0o077).zero? &&
            stat.size <= MAX_BYTES && !File.realpath(path).start_with?(repository)
          raise Error.new("Pi resources require private regular files outside the repository, at most 64 KiB.", code: :invalid_resource)
        end
        stat
      rescue Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR
        raise Error.new("A selected Pi resource is unavailable.", code: :unavailable_resource)
      end

      def read_resource(path)
        resource_stat!(path)
        File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
          stat = file.stat
          unless stat.file? && stat.uid == Process.uid && (stat.mode & 0o077).zero? && stat.size <= MAX_BYTES
            raise Error.new("The selected Pi resource changed or is invalid.", code: :invalid_resource)
          end
          bytes = file.read(MAX_BYTES + 1)
          raise Error.new("The selected Pi resource is too large.", code: :invalid_resource) if bytes.bytesize > MAX_BYTES
          JSON.parse(bytes)
        end
      rescue JSON::ParserError, Errno::ELOOP
        raise Error.new("The selected Pi resource has an invalid format.", code: :invalid_resource)
      rescue Errno::ENOENT, Errno::EACCES
        raise Error.new("A selected Pi resource is unavailable.", code: :unavailable_resource)
      end

      def static_value?(value)
        !value.start_with?("!") && !value.match?(/\$(?:[A-Za-z_]|\{)/) && !value.include?("\u0000")
      end

      def valid_model?(row)
        (!row.key?("name") || (row["name"].is_a?(String) && row["name"].bytesize.between?(1, 128))) &&
          (!row.key?("reasoning") || [true, false].include?(row["reasoning"])) &&
          (!row.key?("input") || (row["input"].is_a?(Array) && row["input"].any? && (row["input"] - %w[text image]).empty?)) &&
          %w[contextWindow maxTokens].all? { |key| !row.key?(key) || (row[key].is_a?(Integer) && row[key].between?(1, 2**31 - 1)) } &&
          (!row.key?("cost") || (row["cost"].is_a?(Hash) && (row["cost"].keys - %w[input output cacheRead cacheWrite]).empty? &&
            row["cost"].values.all? { |number| number.is_a?(Numeric) && number.finite? && number >= 0 })) &&
          (!row.key?("compat") || row["compat"].is_a?(Hash))
      end

      def write_snapshot(scratch, name, value)
        File.write(File.join(scratch, "agent", name), CanonicalJson.dump(value), perm: 0o600)
      end

      def invalid_model!
        raise Error.new("The selected Pi model configuration requires an explicit supported static endpoint and model without credential commands or headers.", code: :unsupported_resource)
      end
    end
  end
end
