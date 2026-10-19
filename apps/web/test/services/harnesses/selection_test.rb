require "test_helper"

class HarnessesSelectionTest < ActiveSupport::TestCase
  test "profiles expose semantic identity and private references separately" do
    # Resolution performs local checks without reading credential bytes or invoking a model.
    Dir.mktmpdir("harness-profiles-") do |root|
      credential = File.join(root, "credential.json")
      File.write(credential, "private credential fixture", perm: 0o600)
      path = File.join(root, "profiles.json")
      profile = {name: "local", harness: "codex", executable_ref: "/bin/true", credential_ref: credential,
        capabilities: {structured_output: true}}
      File.write(path, JSON.generate(version: 1, profiles: [profile]), perm: 0o600)
      registry = Harnesses::ProfileRegistry.new(path: path)
      resolved = registry.resolve("local").ready!
      assert_equal credential, resolved.private_values.fetch("credential_ref")
      assert_equal 64, resolved.public_values.fetch("revision").size
      assert_not_includes resolved.public_values.to_json, root
      assert_not_includes resolved.public_values.to_json, "private credential fixture"
      profile[:requested_model] = "next-model"
      File.write(path, JSON.generate(version: 1, profiles: [profile]))
      assert_not_equal resolved.public_values["revision"], registry.resolve("local").public_values["revision"]
      assert_equal :unknown_profile, assert_raises(Harnesses::Error) { registry.resolve("missing") }.code
      File.chmod(0o644, path)
      assert_equal :invalid_profile, assert_raises(Harnesses::Error) { registry.resolve("local") }.code
    end
  end

  test "profiles reject unsupported adapters and unsafe files" do
    # Private configuration cannot silently become another backend or expose a symlink target.
    Dir.mktmpdir("harness-profiles-") do |root|
      path = File.join(root, "profiles.json")
      cases = {
        "unsupported harness" => [{name: "local", harness: "other", executable_ref: "/bin/true"}],
        "raw credential" => [{name: "local", harness: "codex", executable_ref: "/bin/true", api_key: "fixture"}],
        "too many profiles" => Array.new(65) { |index| {name: "local-#{index}", harness: "codex", executable_ref: "/bin/true"} }
      }
      cases.each do |name, profiles|
        File.write(path, JSON.generate(version: 1, profiles: profiles), perm: 0o600)
        assert_equal :invalid_profile, assert_raises(Harnesses::Error, name) { Harnesses::ProfileRegistry.new(path: path).resolve("local") }.code
      end
      File.symlink(path, File.join(root, "link.json"))
      assert_equal :invalid_profile, assert_raises(Harnesses::Error) { Harnesses::ProfileRegistry.new(path: File.join(root, "link.json")).resolve("local") }.code
      File.write(path, JSON.generate(version: 1, profiles: [{name: "local", harness: "pi", executable_ref: "/bin/true",
        protocol_revision: "1.3.0", requested_model: "model", requested_provider: "provider", capabilities: {structured_output: true}}]))
      assert_equal :unsupported_capability, assert_raises(Harnesses::Error) { Harnesses::ProfileRegistry.new(path: path).resolve("local").ready! }.code
    end
  end
end
