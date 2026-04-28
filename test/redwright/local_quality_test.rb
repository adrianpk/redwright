# frozen_string_literal: true

require "tmpdir"
require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/local_quality"

class LocalQualityTest < Minitest::Test
  def test_writes_expected_artifact_schema
    Dir.mktmpdir("redwright-local-quality-artifact-") do |dir|
      helper = Redwright::LocalQuality.new
      payload = helper.run_step(name: "lint", command: "ruby -e 'exit 0'")
      path = File.join(dir, "tmp", "quality", "lint-status.json")
      helper.write_artifact(path: path, payload: payload)

      stored = JSON.parse(File.read(path))
      assert_equal("lint", stored["name"])
      assert_equal("pass", stored["status"])
      refute_nil(stored["timestamp"])
      assert_equal("ruby -e 'exit 0'", stored["command"])
      assert_equal(0, stored["exit_code"])
      assert(stored["duration_ms"].is_a?(Integer))
    end
  end

  def test_readme_badges_are_rewritten_deterministically
    Dir.mktmpdir("redwright-local-quality-readme-") do |dir|
      helper = Redwright::LocalQuality.new
      readme = File.join(dir, "README.md")
      File.write(readme, "# Demo\n")

      lint = { "name" => "lint", "status" => "pass", "duration_ms" => 1 }
      test = { "name" => "test", "status" => "fail", "duration_ms" => 1 }
      summary = { "name" => "summary", "status" => "fail", "duration_ms" => 2 }
      coverage = { "name" => "coverage", "status" => "pass", "line_percent" => 87.23 }

      helper.render_readme_badges(readme_path: readme, lint: lint, test: test, summary: summary, coverage: coverage)
      first = File.read(readme)
      helper.render_readme_badges(readme_path: readme, lint: lint, test: test, summary: summary, coverage: coverage)
      second = File.read(readme)

      assert_equal(first, second)
      assert_includes(second, "[![CI](https://img.shields.io/badge/CI-failing-red)](https://codeberg.org/adrianpk/redwright)")
      assert_includes(second, "[![coverage](https://img.shields.io/badge/coverage-87.23%-brightgreen)](badges/coverage.svg)")
    end
  end
end
