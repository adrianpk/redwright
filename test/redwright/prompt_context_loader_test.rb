# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/prompt_context_loader"

class PromptContextLoaderTest < Minitest::Test
  def test_build_prefers_project_manifest_when_present
    Dir.mktmpdir("redwright-prompt-context-manifest-") do |dir|
      project_root = File.join(dir, "project")
      FileUtils.mkdir_p(File.join(project_root, ".redwright"))
      File.write(
        File.join(project_root, ".redwright", "manifest.yml"),
        <<~YAML
          project:
            name: "rw-project"
            stack: "ruby"
            summary: "agent runtime"
          architecture:
            context: "Use strict module boundaries."
            conventions:
              - "Keep docs in English"
              - "Prefer table-driven tests"
          quality:
            auto_validate: true
            lint_command: "bundle exec rubocop"
            test_command: "bundle exec rake test"
        YAML
      )

      context = Redwright::PromptContextLoader.new(repo_root: dir).build(project_path: project_root)
      assert_includes(context[:project_context], "Project name: rw-project")
      assert_includes(context[:project_context], "Stack: ruby")
      assert_includes(context[:architecture_context], "Use strict module boundaries.")
      assert_includes(context[:architecture_context], "Keep docs in English")
      assert_includes(context[:architecture_context], "Lint command: bundle exec rubocop")
      assert_equal(true, context.dig(:quality, :auto_validate))
      assert_equal("bundle exec rubocop", context.dig(:quality, :lint_command))
      assert_equal("bundle exec rake test", context.dig(:quality, :test_command))
    end
  end

  def test_build_falls_back_to_agents_policy_when_manifest_missing
    Dir.mktmpdir("redwright-prompt-context-fallback-") do |dir|
      File.write(File.join(dir, "AGENTS.md"), <<~MD)
        # Agent Operating Contract
        - Always keep documentation in English.
        - Never bypass repository guardrails.
      MD
      FileUtils.mkdir_p(File.join(dir, ".agents"))
      File.write(File.join(dir, ".agents", "CONVENTIONS.md"), <<~MD)
        # Conventions
        - Must keep code comments concise.
        - Do not introduce unrelated refactors.
      MD
      File.write(File.join(dir, "AGENTS.md"), <<~MD)
        # Agent Operating Contract
        - `.agents/CONVENTIONS.md` — coding standards.
        - Always keep documentation in English.
      MD

      context = Redwright::PromptContextLoader.new(repo_root: dir).build(project_path: File.join(dir, "project"))
      assert_includes(context[:project_context], "Project context source: AGENTS.md fallback")
      assert_includes(context[:architecture_context], "Fallback conventions and guardrails")
      assert_includes(context[:architecture_context], "Always keep documentation in English")
      assert_includes(context[:architecture_context], "Must keep code comments concise")
      assert_equal(false, context.dig(:quality, :auto_validate))
    end
  end
end
