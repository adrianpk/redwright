require "fileutils"
require "json"
require "open3"
require "timeout"
require "yaml"

module ProjectSetup
  class LocalWorkspaceMaterializer
    DEFAULT_RELATIVE_ROOT = File.join("_workspace", "Projects").freeze
    MATERIALIZATION_STATUS = "materialized_planned".freeze
    INITIAL_IMPLEMENTATION_STATUS = "planned".freeze
    VALIDATION_STATUS = "skipped".freeze
    GO_CLI_PROFILE_KEY = "go_cli".freeze
    GO_CLI_VALIDATION_COMMAND = "go test ./...".freeze
    GO_CLI_VALIDATION_TIMEOUT = 10
    URFAVE_CLI_MODULE = "github.com/urfave/cli/v2".freeze
    URFAVE_CLI_VERSION = "v2.27.6".freeze

    def initialize(session:, project:, starter_ticket: nil, projects_root: nil)
      @session = session
      @project = project
      @starter_ticket = starter_ticket
      @projects_root = projects_root.presence || ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"].presence || default_projects_root
      @scaffold_profile = nil
      @validation_result = nil
    end

    def call
      return skipped_workspace unless local_repository?

      slug = workspace_slug
      path = File.join(@projects_root, slug)
      manifest_dir = File.join(path, ".redwright")
      manifest_path = File.join(manifest_dir, "manifest.yml")
      readme_path = File.join(path, "README.md")
      setup_notes_path = File.join(manifest_dir, "setup-notes.md")

      @scaffold_profile = scaffold_profile
      FileUtils.mkdir_p(path)
      FileUtils.mkdir_p(manifest_dir)
      write_scaffold_files(path) if scaffold_profile?
      @validation_result = validate_scaffold(path)
      File.write(manifest_path, YAML.dump(manifest_payload(manifest_path: manifest_path)))
      File.write(readme_path, readme_body)
      File.write(setup_notes_path, setup_notes_body)

      {
        "status" => "materialized",
        "materialization_status" => materialization_status,
        "initial_implementation_status" => initial_implementation_status,
        "validation_status" => validation_status,
        "validation" => validation_payload,
        "runnable" => runnable?,
        "reason" => materialization_reason,
        "materialized" => true,
        "path" => path,
        "relative_path" => File.join(DEFAULT_RELATIVE_ROOT, slug),
        "manifest_path" => manifest_path,
        "manifest_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, slug, ".redwright", "manifest.yml"),
        "readme_path" => readme_path,
        "readme_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, slug, "README.md"),
        "setup_notes_path" => setup_notes_path,
        "setup_notes_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, slug, ".redwright", "setup-notes.md"),
        "runtime_root_path" => @project.root_path,
        "repo_url" => @project.repo_url,
        "scaffold_profile" => scaffold_profile_key,
        "scaffold_files" => scaffold_files,
        "linked_ticket_ids" => linked_ticket_ids
      }
    end

    private

    def default_projects_root
      return Rails.root.join("tmp", "redwright-local-projects").expand_path.to_s if Rails.env.test?

      Rails.root.join("..", "..", DEFAULT_RELATIVE_ROOT).expand_path.to_s
    end

    def local_repository?
      @project.repo_url.to_s.start_with?("local://")
    end

    def skipped_workspace
      {
        "status" => "skipped",
        "materialization_status" => "skipped",
        "initial_implementation_status" => INITIAL_IMPLEMENTATION_STATUS,
        "validation_status" => VALIDATION_STATUS,
        "validation" => skipped_validation_payload("validation is skipped for non-local repositories"),
        "runnable" => false,
        "materialized" => false,
        "reason" => "non_local_repository",
        "runtime_root_path" => @project.root_path,
        "repo_url" => @project.repo_url,
        "scaffold_profile" => "",
        "scaffold_files" => [],
        "linked_ticket_ids" => linked_ticket_ids
      }
    end

    def workspace_slug
      slug = File.basename(@project.root_path.to_s)
      slug = @project.name.to_s if slug.empty? || slug == "."
      slug.downcase.gsub(/[^a-z0-9._-]+/, "-").gsub(/\A-+|-+\z/, "")
    end

    def manifest_payload(manifest_path:)
      existing = existing_manifest(manifest_path)
      created_at = existing.dig("project", "created_at").presence || Time.current.utc.iso8601

      {
        "schema_version" => 1,
        "project" => {
          "id" => @project.id,
          "name" => @project.name,
          "slug" => workspace_slug,
          "stack" => @project.stack_slug,
          "created_via" => "rails_project_setup",
          "created_at" => created_at
        },
        "rails" => {
          "project_id" => @project.id,
          "root_path" => @project.root_path,
          "repo_url" => @project.repo_url
        },
        "setup_context" => @session.setup_context,
        "materialization" => {
          "status" => materialization_status,
          "runnable" => runnable?,
          "reason" => materialization_reason,
          "workspace_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, workspace_slug),
          "setup_notes_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, workspace_slug, ".redwright", "setup-notes.md")
        },
        "initial_implementation" => {
          "status" => initial_implementation_status,
          "runnable" => runnable?,
          "reason" => initial_implementation_reason,
          "linked_ticket_ids" => linked_ticket_ids
        },
        "scaffold" => scaffold_payload,
        "validation" => validation_payload,
        "runtime" => {
          "container_profile" => slot_value("runtime_container_profile")
        },
        "workflow" => {
          "agent_workflow_mode" => slot_value("agent_workflow_mode"),
          "linked_ticket_ids" => linked_ticket_ids
        }
      }
    end

    def write_scaffold_files(path)
      case scaffold_profile_key
      when GO_CLI_PROFILE_KEY
        File.write(File.join(path, "go.mod"), go_mod_body)
        File.write(File.join(path, "main.go"), go_main_body)
        File.write(File.join(path, "main_test.go"), go_main_test_body)
      end
    end

    def readme_body
      lines = [
        "# #{@project.name}",
        "",
        @project.description.to_s,
        "",
        "## Setup Status",
        "",
        "- Materialization: #{materialization_status}",
        "- Initial implementation: #{initial_implementation_status}",
        "- Runnable: #{runnable? ? "yes" : "no"}",
        "- Validation: #{validation_status}",
        "- Reason: #{materialization_reason}"
      ]
      if scaffold_profile?
        lines.concat(
          [
            "",
            "## Generated Scaffold",
            "",
            "- Profile: #{scaffold_profile_key}",
            "- Module: #{go_module_path}",
            "- Files: #{scaffold_files.join(", ")}",
            "",
            "## Commands",
            "",
            "```sh",
            GO_CLI_VALIDATION_COMMAND,
            "go run .",
            "```"
          ]
        )
      end
      lines.concat(
        [
          "",
          "## Next Step",
          "",
          starter_ticket_line
        ]
      )
      lines.join("\n")
    end

    def setup_notes_body
      lines = [
        "# RedWright Setup Notes",
        "",
        "This workspace was materialized by Rails project setup.",
        "",
        "## Outcome",
        "",
        "- Materialization status: #{materialization_status}",
        "- Initial implementation status: #{initial_implementation_status}",
        "- Validation status: #{validation_status}",
        "- Runnable: #{runnable? ? "yes" : "no"}",
        "- Reason: #{materialization_reason}",
        "",
        "## Canonical Setup Slots"
      ]
      @session.setup_slots.each_value do |slot|
        lines << "- #{slot.fetch("key")}: #{slot["value"]} (#{slot["status"]})"
      end
      if scaffold_profile?
        lines.concat(
          [
            "",
            "## Scaffold",
            "",
            "- Profile: #{scaffold_profile_key}",
            "- Module: #{go_module_path}",
            "- Dependencies: #{scaffold_dependencies.any? ? scaffold_dependencies.join(", ") : "none"}",
            "- Files: #{scaffold_files.join(", ")}",
            "- Validation command: #{GO_CLI_VALIDATION_COMMAND}",
            "- Validation reason: #{validation_payload.fetch("reason")}"
          ]
        )
      end
      lines.concat(
        [
          "",
          "## Linked Tickets",
          "",
          starter_ticket_line
        ]
      )
      lines.join("\n")
    end

    def starter_ticket_line
      return "- Initial implementation ticket: #{@starter_ticket.id}" if @starter_ticket

      "- Initial implementation ticket: pending"
    end

    def scaffold_profile
      return nil unless go_cli_context?

      {
        "key" => GO_CLI_PROFILE_KEY,
        "language" => "Go",
        "archetype" => "cli",
        "module_path" => go_module_path,
        "go_version" => go_directive_version,
        "dependencies" => scaffold_dependencies
      }
    end

    def scaffold_profile?
      @scaffold_profile.is_a?(Hash)
    end

    def scaffold_profile_key
      scaffold_profile? ? @scaffold_profile.fetch("key") : ""
    end

    def scaffold_payload
      return {"profile" => "", "files" => [], "dependencies" => []} unless scaffold_profile?

      @scaffold_profile.merge("profile" => scaffold_profile_key, "files" => scaffold_files)
    end

    def scaffold_files
      scaffold_profile? ? %w[go.mod main.go main_test.go] : []
    end

    def scaffold_dependencies
      uses_urfave_cli? ? [URFAVE_CLI_MODULE] : []
    end

    def uses_urfave_cli?
      slot_value("libraries").downcase.match?(/urfave\s*\/\s*cli|github\.com\/urfave\/cli/)
    end

    def materialization_status
      return MATERIALIZATION_STATUS unless scaffold_profile?
      return "materialized_runnable" if validation_status == "passed"
      return "materialized_failed" if validation_status == "failed"

      "materialized_scaffolded"
    end

    def initial_implementation_status
      scaffold_profile? ? "scaffolded" : INITIAL_IMPLEMENTATION_STATUS
    end

    def validation_status
      validation_payload.fetch("status")
    end

    def runnable?
      scaffold_profile? && validation_status == "passed"
    end

    def materialization_reason
      if scaffold_profile?
        return "Go CLI scaffold generated and validated" if validation_status == "passed"
        return "Go CLI scaffold generated but validation failed" if validation_status == "failed"

        "Go CLI scaffold generated; #{validation_payload.fetch("reason")}"
      else
        "no runnable scaffold profile exists for this setup context yet"
      end
    end

    def initial_implementation_reason
      return "initial scaffold files were generated in the local workspace" if scaffold_profile?

      "initial implementation is represented by a Rails board ticket"
    end

    def validation_payload
      @validation_result ||= if scaffold_profile?
        skipped_validation_payload("validation has not run")
      else
        skipped_validation_payload("validation is skipped until a runnable scaffold exists")
      end
    end

    def validate_scaffold(path)
      return skipped_validation_payload("validation is skipped until a runnable scaffold exists") unless scaffold_profile?
      return skipped_validation_payload("validation is skipped for scaffold profiles with external dependencies") if scaffold_dependencies.any?
      return skipped_validation_payload("Go toolchain is unavailable") unless go_available?

      stdout, stderr, status = Timeout.timeout(GO_CLI_VALIDATION_TIMEOUT) do
        Open3.capture3({"GOTOOLCHAIN" => "local"}, "go", "test", "./...", chdir: path)
      end
      combined = [stdout, stderr].join("\n").strip
      {
        "status" => status.success? ? "passed" : "failed",
        "command" => GO_CLI_VALIDATION_COMMAND,
        "reason" => status.success? ? "go test ./... passed" : "go test ./... failed",
        "exit_status" => status.exitstatus,
        "output" => combined[0, 4000]
      }
    rescue Errno::ENOENT
      skipped_validation_payload("Go toolchain is unavailable")
    rescue Timeout::Error
      {
        "status" => "failed",
        "command" => GO_CLI_VALIDATION_COMMAND,
        "reason" => "go test ./... timed out",
        "exit_status" => nil,
        "output" => ""
      }
    end

    def skipped_validation_payload(reason)
      {
        "status" => VALIDATION_STATUS,
        "command" => scaffold_profile? ? GO_CLI_VALIDATION_COMMAND : "",
        "reason" => reason,
        "exit_status" => nil,
        "output" => ""
      }
    end

    def go_available?
      system("go", "version", out: File::NULL, err: File::NULL)
    end

    def go_mod_body
      lines = [
        "module #{go_module_path}",
        "",
        "go #{go_directive_version}"
      ]
      if uses_urfave_cli?
        lines.concat(
          [
            "",
            "require #{URFAVE_CLI_MODULE} #{URFAVE_CLI_VERSION}"
          ]
        )
      end
      lines.join("\n") + "\n"
    end

    def go_main_body
      uses_urfave_cli? ? urfave_cli_main_body : standard_go_main_body
    end

    def standard_go_main_body
      <<~GO
        package main

        import (
        \t"fmt"
        \t"io"
        \t"os"
        )

        const appName = #{go_string(@project.name)}
        const appDescription = #{go_string(@project.description.to_s)}

        func main() {
        \tif err := run(os.Args[1:], os.Stdout); err != nil {
        \t\tfmt.Fprintln(os.Stderr, err)
        \t\tos.Exit(1)
        \t}
        }

        func run(args []string, writer io.Writer) error {
        \tif len(args) > 0 && (args[0] == "-h" || args[0] == "--help") {
        \t\t_, err := fmt.Fprintf(writer, "%s\\n%s\\n", appName, appDescription)
        \t\treturn err
        \t}

        \t_, err := fmt.Fprintln(writer, appName)
        \treturn err
        }
      GO
    end

    def urfave_cli_main_body
      <<~GO
        package main

        import (
        \t"fmt"
        \t"io"
        \t"os"

        \t"#{URFAVE_CLI_MODULE}"
        )

        const appName = #{go_string(@project.name)}
        const appDescription = #{go_string(@project.description.to_s)}

        func main() {
        \tif err := newApp(os.Stdout).Run(os.Args); err != nil {
        \t\tfmt.Fprintln(os.Stderr, err)
        \t\tos.Exit(1)
        \t}
        }

        func newApp(writer io.Writer) *cli.App {
        \treturn &cli.App{
        \t\tName:  appName,
        \t\tUsage: appDescription,
        \t\tAction: func(ctx *cli.Context) error {
        \t\t\t_, err := fmt.Fprintln(writer, appName)
        \t\t\treturn err
        \t\t},
        \t}
        }
      GO
    end

    def go_main_test_body
      uses_urfave_cli? ? urfave_cli_test_body : standard_go_test_body
    end

    def standard_go_test_body
      <<~GO
        package main

        import (
        \t"bytes"
        \t"strings"
        \t"testing"
        )

        func TestRunPrintsProjectName(t *testing.T) {
        \tvar out bytes.Buffer
        \tif err := run(nil, &out); err != nil {
        \t\tt.Fatalf("run returned error: %v", err)
        \t}
        \tif !strings.Contains(out.String(), appName) {
        \t\tt.Fatalf("expected output to include %q, got %q", appName, out.String())
        \t}
        }
      GO
    end

    def urfave_cli_test_body
      <<~GO
        package main

        import (
        \t"bytes"
        \t"strings"
        \t"testing"
        )

        func TestAppRuns(t *testing.T) {
        \tvar out bytes.Buffer
        \tapp := newApp(&out)
        \tif err := app.Run([]string{appName}); err != nil {
        \t\tt.Fatalf("app returned error: %v", err)
        \t}
        \tif !strings.Contains(out.String(), appName) {
        \t\tt.Fatalf("expected output to include %q, got %q", appName, out.String())
        \t}
        }
      GO
    end

    def go_string(value)
      JSON.generate(value.to_s)
    end

    def go_module_path
      "example.com/redwright/#{go_module_slug}"
    end

    def go_module_slug
      slug = workspace_slug.gsub(/[^a-z0-9-]+/, "-").gsub(/\A-+|-+\z/, "")
      slug.empty? ? "project" : slug
    end

    def go_directive_version
      version = slot_value("language_runtime").match(/(?:go\s*)?(\d+\.\d+)(?:\.\d+)?/i)&.captures&.first
      version.presence || "1.22"
    end

    def linked_ticket_ids
      @starter_ticket ? [@starter_ticket.id] : []
    end

    def go_cli_context?
      [slot_value("project_type"), slot_value("language_runtime")].join(" ").downcase.match?(/\bcli\b.*\bgo\b|\bgo\b.*\bcli\b/)
    end

    def existing_manifest(path)
      return {} unless File.file?(path)

      parsed = YAML.safe_load(File.read(path), aliases: false)
      parsed.is_a?(Hash) ? parsed : {}
    rescue Psych::Exception
      {}
    end

    def slot_value(key)
      slot = @session.setup_slot(key)
      return "" unless slot.is_a?(Hash)

      slot["value"].to_s
    end
  end
end
