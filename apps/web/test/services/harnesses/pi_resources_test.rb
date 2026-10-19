require "test_helper"

class HarnessesPiResourcesTest < ActiveSupport::TestCase
  setup do
    @project = create_project
    @resources_root = Dir.mktmpdir("pi-selected-resources-")
    @protocol_test_directories << @resources_root
    @auth = File.join(@resources_root, "auth.json")
    @models = File.join(@resources_root, "models.json")
    write_auth({"selected" => {"type" => "api_key", "key" => "owned-static-sentinel"},
      "unrelated" => {"type" => "oauth", "access" => "unrelated-credential-sentinel"}})
    @configuration = {"providers" => {"selected" => {"baseUrl" => "http://127.0.0.1:12345/v1", "api" => "openai-completions",
      "models" => [{"id" => "bounded-model", "reasoning" => false, "input" => ["text"], "contextWindow" => 32768, "maxTokens" => 1024}, {"id" => "unrelated-model"}]},
      "unrelated" => {"apiKey" => "!unrelated command"}}}
    write_models
    @resources = {"credential_ref" => @auth, "model_config_ref" => @models}
  end

  test "only the selected static resources enter scratch" do
    # Snapshotting filters other providers/models and never mutates either source file.
    auth_before, models_before = File.binread(@auth), File.binread(@models)
    Dir.mktmpdir("pi-resource-snapshot-") do |scratch|
      Dir.mkdir(File.join(scratch, "agent"))
      Harnesses::PiResources.prepare!(resource_request, scratch)
      selected = JSON.parse(File.read(File.join(scratch, "agent/auth.json")))
      assert_equal ["selected"], selected.keys
      assert_equal "owned-static-sentinel", selected.dig("selected", "key")
      config = JSON.parse(File.read(File.join(scratch, "agent/models.json")))
      assert_equal ["selected"], config.fetch("providers").keys
      assert_equal ["bounded-model"], config.dig("providers", "selected", "models").map { |row| row["id"] }
      assert_not_includes config.to_json, "unrelated"
      settings = JSON.parse(File.read(File.join(scratch, "agent/settings.json")))
      assert_equal "never", settings["defaultProjectTrust"]
      assert_equal [], settings["defaultTools"]
      assert_equal "off", settings["cacheWarming"]
      Dir.glob(File.join(scratch, "agent/*")).each { |path| assert_equal 0o600, File.stat(path).mode & 0o777 }
      write_auth({"selected" => {"type" => "api_key", "key" => "rotated-fixture"}})
      assert_equal selected, JSON.parse(File.read(File.join(scratch, "agent/auth.json")))
    end
    assert_equal models_before, File.binread(@models)
    assert_not_equal auth_before, File.binread(@auth)
  end

  test "dynamic or OAuth credentials never enter a call" do
    # The adapter cannot execute commands, expand ambient secrets or refresh provider credentials.
    cases = {
      "command" => {"type" => "api_key", "key" => "!printf secret"},
      "environment" => {"type" => "api_key", "key" => "${PROVIDER_SECRET}"},
      "credential environment" => {"type" => "api_key", "key" => "literal", "env" => {"X" => "secret"}},
      "OAuth" => {"type" => "oauth", "access" => "secret", "refresh" => "secret", "expires" => 1}
    }
    cases.each do |name, row|
      write_auth({"selected" => row})
      Dir.mktmpdir("pi-rejected-resource-") do |scratch|
        Dir.mkdir(File.join(scratch, "agent"))
        error = assert_raises(Harnesses::Error, name) { Harnesses::PiResources.prepare!(resource_request, scratch) }
        assert_equal :unsupported_auth, error.code
        assert_empty Dir.children(File.join(scratch, "agent"))
        assert_not_includes error.message + error.diagnostics.to_json, row.to_json
      end
    end
  end

  test "readiness does not read credential bytes" do
    # Local availability is distinct from credential validation and never probes a provider.
    File.write(@auth, "invalid JSON, not read during readiness")
    assert_equal resource_request.binding["model_config_revision"], Harnesses::PiResources.ready!(binding: resource_request.binding, resources: @resources)
  end

  test "private regular resource files are mandatory" do
    # Symlinks, public files, excessive input and workspace files cannot become selected secrets.
    link = File.join(@resources_root, "link")
    File.symlink(@auth, link)
    public_path = File.join(@resources_root, "public.json")
    File.write(public_path, "{}", perm: 0o644)
    large_path = File.join(@resources_root, "large.json")
    File.write(large_path, " " * (64 * 1024 + 1), perm: 0o600)
    {"link" => link, "public" => public_path, "oversized" => large_path}.each do |name, path|
      assert_equal :invalid_resource, assert_raises(Harnesses::Error, name) {
        Harnesses::PiResources.ready!(binding: resource_request.binding, resources: @resources.merge("credential_ref" => path))
      }.code
    end
    local = File.join(@project.root_path, "local-auth.json")
    File.write(local, File.read(@auth), perm: 0o600)
    request = resource_request(resources: @resources.merge("credential_ref" => local))
    assert_equal :invalid_resource, assert_raises(Harnesses::Error) { Harnesses::PiResources.prepare!(request, @resources_root) }.code
  end

  test "model configuration is static and revision checked" do
    # Endpoint or model changes cannot silently alter an already retained binding.
    original = resource_request
    @configuration["providers"]["selected"]["baseUrl"] = "http://127.0.0.1:23456/v1"
    write_models
    assert_equal :invalid_binding, assert_raises(Harnesses::Error) { Harnesses::PiResources.ready!(binding: original.binding, resources: @resources) }.code
    {"apiKey" => "!credential-command", "headers" => {"X-Key" => "secret"}, "modelOverrides" => {}}.each do |field, value|
      @configuration["providers"]["selected"][field] = value
      write_models
      assert_equal :unsupported_resource, assert_raises(Harnesses::Error) { resource_request }.code
      @configuration["providers"]["selected"].delete(field)
    end
  end

  test "prepared profile readiness has no executable side effects" do
    # Metadata establishes local compatibility; the actual binary version and namespace proof are still checked at call time.
    executable = File.join(@resources_root, "program")
    FileUtils.cp(File.realpath("/bin/true"), executable)
    File.write(File.join(@resources_root, "package.json"), JSON.generate(name: "@earendil-works/pi-coding-agent", version: "1.3.0"))
    profiles = File.join(@resources_root, "profiles.json")
    row = {name: "prepared", harness: "pi", executable_ref: executable, protocol_revision: "1.3.0",
      requested_provider: "selected", requested_model: "bounded-model", credential_ref: @auth, model_config_ref: @models,
      capabilities: {structured_output: true, os_read_only_containment: true}}
    File.write(profiles, JSON.generate(version: 1, profiles: [row]), perm: 0o600)
    resolved = Harnesses::ProfileRegistry.new(path: profiles).resolve("prepared").ready!
    assert_equal "pi-linux-bwrap/v1", resolved.public_values["containment_policy_revision"]
    assert_equal resource_request.binding["model_config_revision"], resolved.public_values["model_config_revision"]
    assert_not_includes resolved.public_values.to_json, @resources_root
    assert_not_includes resolved.public_values.to_json, "owned-static-sentinel"
    File.write(File.join(@resources_root, "package.json"), JSON.generate(name: "@earendil-works/pi-coding-agent", version: "1.2.0"))
    assert_equal :unsupported_version, assert_raises(Harnesses::Error) { resolved.ready! }.code
  end

  private

  def resource_request(resources: @resources)
    snapshot = Harnesses::PiResources.model_snapshot(@models, provider: "selected", model: "bounded-model")
    binding = {"requested_provider" => "selected", "requested_model" => "bounded-model", "model_config_revision" => Harnesses::CanonicalJson.digest(snapshot)}
    Harnesses::Request.new(instructions: "Bounded fixture.", context: {}, workspace: @project.root_path,
      schema: {}, purpose: "specification", harness: "pi", binding: binding, resources: resources)
  end

  def write_auth(value)
    File.write(@auth, JSON.generate(value), perm: 0o600)
  end

  def write_models
    File.write(@models, JSON.generate(@configuration), perm: 0o600)
  end
end
