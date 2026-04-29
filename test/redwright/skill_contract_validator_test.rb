# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/skill_loader"
require "redwright/skill_contract_validator"

class SkillContractValidatorTest < Minitest::Test
  def test_validates_required_fields_and_dry_run_support
    base_dir = File.expand_path("../fixtures/skills", __dir__)
    manifest = Redwright::SkillLoader.new(base_dir: base_dir).load("repo-bootstrap")
    validator = Redwright::SkillContractValidator.new

    valid = validator.validate(
      manifest: manifest,
      input: { "project_name" => "demo", "remote_url" => "https://example.com/repo.git", "dry_run" => true }
    )
    assert_equal(true, valid.valid)
    assert_equal([], valid.errors)

    invalid = validator.validate(
      manifest: manifest,
      input: { "project_name" => "", "remote_url" => "", "dry_run" => false }
    )
    assert_equal(false, invalid.valid)
    assert_includes(invalid.errors, "missing_required_field:project_name")
    assert_includes(invalid.errors, "missing_required_field:remote_url")
  end
end
