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
          schema_version: 1
          project:
            id: "rw-project-id"
            name: "rw-project"
            slug: "rw-project"
            stack: "ruby"
            created_via: "new"
            created_at: "2026-04-29T10:00:00Z"
            summary: "agent runtime"
          provenance:
            remote_url: "https://example.com/acme/rw-project.git"
            provider: "example"
            ref: "main"
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
      assert_includes(context[:project_context], "Project id: rw-project-id")
      assert_includes(context[:project_context], "Project name: rw-project")
      assert_includes(context[:project_context], "Project slug: rw-project")
      assert_includes(context[:project_context], "Created via: new")
      assert_includes(context[:project_context], "Source remote: https://example.com/acme/rw-project.git")
      assert_includes(context[:project_context], "Stack: ruby")
      assert_includes(context[:architecture_context], "Use strict module boundaries.")
      assert_includes(context[:architecture_context], "Keep docs in English")
      assert_includes(context[:architecture_context], "Lint command: bundle exec rubocop")
      assert_includes(context[:workspace_context], "Workspace root:")
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
      assert_includes(context[:workspace_context], "Workspace unavailable.")
      assert_equal(false, context.dig(:quality, :auto_validate))
    end
  end

  def test_build_uses_fallback_architecture_when_manifest_omits_architecture_context
    Dir.mktmpdir("redwright-prompt-context-manifest-partial-") do |dir|
      project_root = File.join(dir, "project")
      FileUtils.mkdir_p(File.join(project_root, ".redwright"))
      File.write(File.join(dir, "AGENTS.md"), <<~MD)
        # Agent Operating Contract
        - Always keep documentation in English.
        - Never bypass repository guardrails.
      MD
      File.write(
        File.join(project_root, ".redwright", "manifest.yml"),
        <<~YAML
          schema_version: 1
          project:
            id: "partial-id"
            name: "partial"
            slug: "partial"
            stack: "go"
            created_via: "new"
            created_at: "2026-04-29T10:00:00Z"
        YAML
      )

      context = Redwright::PromptContextLoader.new(repo_root: dir).build(project_path: project_root)
      assert_includes(context[:project_context], "Project name: partial")
      assert_includes(context[:architecture_context], "Fallback conventions and guardrails")
      assert_includes(context[:architecture_context], "Always keep documentation in English")
      assert_equal(false, context.dig(:quality, :auto_validate))
      assert_nil(context.dig(:quality, :lint_command))
      assert_nil(context.dig(:quality, :test_command))
    end
  end
end
