# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"

module Redwright
  module CodexProof
    class ContainerSmoke
      DEFAULT_IMAGE_NAME = "redwright-codex-proof-go:local"

      attr_reader :dockerfile, :context_dir, :image_name, :command_runner

      def initialize(
        dockerfile:,
        context_dir:,
        image_name: DEFAULT_IMAGE_NAME,
        command_runner: Open3.method(:capture3)
      )
        @dockerfile = dockerfile
        @context_dir = context_dir
        @image_name = image_name
        @command_runner = command_runner
      end

      def build_image
        stdout, stderr, status = command_runner.call(
          "docker",
          "build",
          "-f",
          dockerfile,
          "-t",
          image_name,
          context_dir
        )

        {
          "status" => status.success? ? "built" : "docker_build_failed",
          "image_name" => image_name,
          "stdout" => stdout,
          "stderr" => stderr,
          "exit_status" => status.exitstatus
        }
      end

      def run_container(input_packet:, output_directory:, env: {})
        smoke_command = <<~SH.strip
          test -f /redwright/input/packet.json &&
          test -d /redwright/output &&
          printf '{"status":"container_smoke_passed","packet_path":"/redwright/input/packet.json"}\n' > /redwright/output/smoke-result.json
        SH

        args = [
          "docker",
          "run",
          "--rm",
          "-v",
          "#{File.expand_path(input_packet)}:/redwright/input/packet.json:ro",
          "-v",
          "#{File.expand_path(output_directory)}:/redwright/output:rw"
        ]

        env.each do |key, value|
          args.concat(["-e", "#{key}=#{value}"])
        end

        args.concat([image_name, "sh", "-lc", smoke_command])

        stdout, stderr, status = command_runner.call(*args)

        {
          "status" => status.success? ? "container_started" : "docker_run_failed",
          "image_name" => image_name,
          "stdout" => stdout,
          "stderr" => stderr,
          "exit_status" => status.exitstatus,
          "smoke_result" => File.join(File.expand_path(output_directory), "smoke-result.json")
        }
      end

      def clone_repository(input_packet:, output_directory:, workspace_directory:, env: {})
        clone_command = <<~SH.strip
          set -eu
          packet=/redwright/input/packet.json
          repo_url=$(node -e 'const fs = require("fs"); console.log(JSON.parse(fs.readFileSync(process.argv[1], "utf8")).repository_url)' "$packet")
          branch=$(node -e 'const fs = require("fs"); console.log(JSON.parse(fs.readFileSync(process.argv[1], "utf8")).result_branch)' "$packet")
          git config --global --add safe.directory '*'
          git clone "$repo_url" /redwright/workspace/repo
          cd /redwright/workspace/repo
          git checkout -B "$branch"
          git rev-parse HEAD > /redwright/output/checkout-revision.txt
          git status --short --branch > /redwright/output/checkout-status.txt
          node -e 'const fs = require("fs"); console.log(JSON.stringify({status: "repository_cloned", repository_url: process.argv[1], result_branch: process.argv[2], checkout_revision: fs.readFileSync("/redwright/output/checkout-revision.txt", "utf8").trim(), workspace_path: "/redwright/workspace/repo"}, null, 2))' "$repo_url" "$branch" > /redwright/output/clone-result.json
        SH

        args = [
          "docker",
          "run",
          "--rm",
          "-v",
          "#{File.expand_path(input_packet)}:/redwright/input/packet.json:ro",
          "-v",
          "#{File.expand_path(output_directory)}:/redwright/output:rw",
          "-v",
          "#{File.expand_path(workspace_directory)}:/redwright/workspace:rw"
        ]

        env.each do |key, value|
          args.concat(["-e", "#{key}=#{value}"])
        end

        args.concat([image_name, "sh", "-lc", clone_command])

        stdout, stderr, status = command_runner.call(*args)

        {
          "status" => status.success? ? "repository_cloned" : "repository_clone_failed",
          "image_name" => image_name,
          "stdout" => stdout,
          "stderr" => stderr,
          "exit_status" => status.exitstatus,
          "clone_result" => File.join(File.expand_path(output_directory), "clone-result.json"),
          "workspace_path" => File.join(File.expand_path(workspace_directory), "repo")
        }
      end

      def preflight_credentials(output_directory:, env: {})
        preflight_command = <<~SH.strip
          set -eu
          status=preflight_passed
          failures=''
          codex_version=''
          if command -v codex >/dev/null 2>&1; then
            codex_version=$(codex --version 2>/dev/null || true)
          else
            status=preflight_failed
            failures="${failures}codex_unavailable "
          fi
          if [ -z "${CODEX_API_KEY:-}" ] && [ -z "${OPENAI_API_KEY:-}" ]; then
            status=preflight_failed
            failures="${failures}codex_auth_missing "
          fi
          if [ -z "${CODEBERG_PUSH_TOKEN:-}" ]; then
            status=preflight_failed
            failures="${failures}codeberg_push_auth_missing "
          fi
          node -e 'const fs = require("fs"); const failures = process.argv[1].trim().split(/\\s+/).filter(Boolean); console.log(JSON.stringify({status: process.argv[2], codex_version: process.argv[3], failures}, null, 2))' "$failures" "$status" "$codex_version" > /redwright/output/preflight-result.json
          test "$status" = preflight_passed
        SH

        args = [
          "docker",
          "run",
          "--rm",
          "-v",
          "#{File.expand_path(output_directory)}:/redwright/output:rw"
        ]

        env.each do |key, value|
          args.concat(["-e", "#{key}=#{value}"])
        end

        args.concat([image_name, "sh", "-lc", preflight_command])

        stdout, stderr, status = command_runner.call(*args)

        {
          "status" => status.success? ? "preflight_passed" : "preflight_failed",
          "image_name" => image_name,
          "stdout" => stdout,
          "stderr" => stderr,
          "exit_status" => status.exitstatus,
          "preflight_result" => File.join(File.expand_path(output_directory), "preflight-result.json")
        }
      end

      def execute_codex_task(input_packet:, output_directory:, workspace_directory:, env: {}, timeout_seconds: 900)
        FileUtils.mkdir_p(output_directory)
        prompt_path = File.join(output_directory, "codex-prompt.txt")
        File.write(prompt_path, codex_prompt(input_packet))

        execution_command = <<~SH.strip
          set -eu
          packet=/redwright/input/packet.json
          repo_url=$(node -e 'const fs = require("fs"); console.log(JSON.parse(fs.readFileSync(process.argv[1], "utf8")).repository_url)' "$packet")
          branch=$(node -e 'const fs = require("fs"); console.log(JSON.parse(fs.readFileSync(process.argv[1], "utf8")).result_branch)' "$packet")
          timeout_seconds=#{Integer(timeout_seconds)}
          git config --global --add safe.directory '*'
          git clone "$repo_url" /redwright/workspace/repo
          cd /redwright/workspace/repo
          git checkout -B "$branch"
          set +e
          timeout "${timeout_seconds}s" codex exec --json --color never --sandbox workspace-write -C /redwright/workspace/repo --output-last-message /redwright/output/codex-last-message.txt - < /redwright/output/codex-prompt.txt > /redwright/output/codex-events.jsonl 2> /redwright/output/codex-stderr.log
          codex_status=$?
          set -e
          timed_out=false
          if [ "$codex_status" -eq 124 ]; then
            timed_out=true
          fi
          git status --short --branch > /redwright/output/post-codex-status.txt || true
          node -e 'const fs = require("fs"); const status = Number(process.argv[1]); console.log(JSON.stringify({status: status === 0 ? "codex_executed" : "codex_execution_failed", codex_exit_status: status, timed_out: process.argv[2] === "true", prompt_path: "/redwright/output/codex-prompt.txt", events_path: "/redwright/output/codex-events.jsonl", stderr_path: "/redwright/output/codex-stderr.log", last_message_path: "/redwright/output/codex-last-message.txt", post_status_path: "/redwright/output/post-codex-status.txt", workspace_path: "/redwright/workspace/repo"}, null, 2))' "$codex_status" "$timed_out" > /redwright/output/codex-execution-result.json
          exit "$codex_status"
        SH

        args = [
          "docker",
          "run",
          "--rm",
          "-v",
          "#{File.expand_path(input_packet)}:/redwright/input/packet.json:ro",
          "-v",
          "#{File.expand_path(output_directory)}:/redwright/output:rw",
          "-v",
          "#{File.expand_path(workspace_directory)}:/redwright/workspace:rw"
        ]

        env.each do |key, value|
          args.concat(["-e", "#{key}=#{value}"])
        end

        args.concat([image_name, "sh", "-lc", execution_command])

        stdout, stderr, status = command_runner.call(*args)

        {
          "status" => status.success? ? "codex_executed" : "codex_execution_failed",
          "image_name" => image_name,
          "stdout" => stdout,
          "stderr" => stderr,
          "exit_status" => status.exitstatus,
          "timed_out" => status.exitstatus == 124,
          "codex_prompt" => prompt_path,
          "codex_events" => File.join(File.expand_path(output_directory), "codex-events.jsonl"),
          "codex_stderr" => File.join(File.expand_path(output_directory), "codex-stderr.log"),
          "codex_last_message" => File.join(File.expand_path(output_directory), "codex-last-message.txt"),
          "codex_execution_result" => File.join(File.expand_path(output_directory), "codex-execution-result.json"),
          "post_codex_status" => File.join(File.expand_path(output_directory), "post-codex-status.txt"),
          "workspace_path" => File.join(File.expand_path(workspace_directory), "repo")
        }
      end

      def codex_prompt(input_packet)
        packet = JSON.parse(File.read(input_packet))
        <<~PROMPT
          You are working on a RedWright black-box engine proof task inside a disposable container workspace.

          Treat this as a normal implementation ticket, not as a step-by-step script.

          Repository:
          #{packet.fetch("repository_url")}

          Result branch:
          #{packet.fetch("result_branch")}

          Task:
          #{packet.fetch("task_prompt")}

          Validation command:
          #{packet.fetch("validation_command")}

          Requirements:
          - Implement the requested mark-as-read behavior in the cloned Go todo application.
          - Add or update automated tests that prove the behavior.
          - Preserve existing behavior unless the task requires a change.
          - Run the validation command when implementation is complete.
          - Do not commit, push, or edit files outside this repository checkout.
          - Leave the workspace in a reviewable state with source changes and tests present.
        PROMPT
      end
    end
  end
end
