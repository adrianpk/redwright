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
          validation_command=$(node -e 'const fs = require("fs"); console.log(JSON.parse(fs.readFileSync(process.argv[1], "utf8")).validation_command)' "$packet")
          timeout_seconds=#{Integer(timeout_seconds)}
          git config --global --add safe.directory '*'
          git clone "$repo_url" /redwright/workspace/repo
          cd /redwright/workspace/repo
          git checkout -B "$branch"
          : > /redwright/output/git-commit.log
          : > /redwright/output/git-push.log
          : > /redwright/output/validation-stdout.log
          : > /redwright/output/validation-stderr.log
          set +e
          timeout "${timeout_seconds}s" codex exec --json --color never --sandbox workspace-write -C /redwright/workspace/repo --output-last-message /redwright/output/codex-last-message.txt - < /redwright/output/codex-prompt.txt > /redwright/output/codex-events.jsonl 2> /redwright/output/codex-stderr.log
          codex_status=$?
          set -e
          timed_out=false
          if [ "$codex_status" -eq 124 ]; then
            timed_out=true
          fi
          git status --short --branch > /redwright/output/post-codex-status.txt || true
          git add -N . >/dev/null 2>&1 || true
          git status --short | sed 's/^...//' | sort -u > /redwright/output/changed-files.txt
          git diff --binary HEAD > /redwright/output/git-diff.patch || true
          has_diff=false
          if [ -s /redwright/output/changed-files.txt ]; then
            has_diff=true
          fi
          final_status=codex_executed
          commit_sha=''
          push_status=not_attempted
          push_exit_status=''
          validation_status=not_run
          validation_exit_status=''
          validation_timed_out=false
          if [ "$codex_status" -ne 0 ]; then
            final_status=codex_execution_failed
            if grep -q '401 Unauthorized' /redwright/output/codex-stderr.log; then
              final_status=codex_auth_failed
            fi
          elif [ "$has_diff" != true ]; then
            final_status=codex_no_diff
          else
            set +e
            timeout "${timeout_seconds}s" sh -lc "$validation_command" > /redwright/output/validation-stdout.log 2> /redwright/output/validation-stderr.log
            validation_exit_status=$?
            set -e
            if [ "$validation_exit_status" -eq 124 ]; then
              validation_timed_out=true
              validation_status=timed_out
              final_status=codex_validation_failed
            elif [ "$validation_exit_status" -eq 0 ]; then
              validation_status=passed
            else
              validation_status=failed
              final_status=codex_validation_failed
            fi
          fi
          if [ "$final_status" = codex_executed ]; then
            git config user.name "RedWright Codex Proof"
            git config user.email "redwright-codex-proof@example.invalid"
            git add -A
            git commit -m "feat: implement mark as read proof task" > /redwright/output/git-commit.log 2>&1
            commit_sha=$(git rev-parse HEAD)
            git rev-parse HEAD > /redwright/output/result-commit.txt
            if [ -n "${CODEBERG_PUSH_TOKEN:-}" ]; then
              remote_url="$repo_url"
              if printf '%s' "$repo_url" | grep -q '^https://codeberg.org/'; then
                remote_url=$(printf '%s' "$repo_url" | sed "s#^https://#https://${CODEBERG_PUSH_USER:-adrianpk}:${CODEBERG_PUSH_TOKEN}@#")
              fi
              set +e
              git push "$remote_url" "HEAD:$branch" > /redwright/output/git-push.log 2>&1
              push_exit_status=$?
              set -e
              if [ "$push_exit_status" -eq 0 ]; then
                push_status=pushed
                final_status=codex_result_pushed
              else
                push_status=failed
                final_status=codex_push_failed
              fi
            else
              push_status=auth_missing
              final_status=codex_push_failed
              printf 'CODEBERG_PUSH_TOKEN is required to push the result branch.\n' > /redwright/output/git-push.log
            fi
          fi
          node -e 'const fs = require("fs"); const changedPath = "/redwright/output/changed-files.txt"; const changed = fs.existsSync(changedPath) ? fs.readFileSync(changedPath, "utf8").trim().split(/\\n/).filter(Boolean) : []; const result = {status: process.argv[1], codex_exit_status: Number(process.argv[2]), timed_out: process.argv[3] === "true", has_diff: process.argv[4] === "true", changed_files: changed, commit_sha: process.argv[5], push_status: process.argv[6], push_exit_status: process.argv[7] === "" ? null : Number(process.argv[7]), validation: {status: process.argv[8], command: process.argv[9], exit_status: process.argv[10] === "" ? null : Number(process.argv[10]), timed_out: process.argv[11] === "true", stdout_path: "/redwright/output/validation-stdout.log", stderr_path: "/redwright/output/validation-stderr.log"}, prompt_path: "/redwright/output/codex-prompt.txt", events_path: "/redwright/output/codex-events.jsonl", stderr_path: "/redwright/output/codex-stderr.log", last_message_path: "/redwright/output/codex-last-message.txt", post_status_path: "/redwright/output/post-codex-status.txt", changed_files_path: "/redwright/output/changed-files.txt", diff_path: "/redwright/output/git-diff.patch", commit_log_path: "/redwright/output/git-commit.log", push_log_path: "/redwright/output/git-push.log", workspace_path: "/redwright/workspace/repo"}; console.log(JSON.stringify(result, null, 2)); fs.writeFileSync("/redwright/output/result-envelope.json", JSON.stringify({schema_version: 1, backend: "codex", status: result.status, summary: {has_diff: result.has_diff, changed_file_count: result.changed_files.length, push_status: result.push_status, validation_status: result.validation.status}, result_branch: process.argv[12], commit_sha: result.commit_sha, pushed_branch: result.push_status === "pushed" ? process.argv[12] : null, changed_files: result.changed_files, diff_path: result.diff_path, validation: result.validation, raw_events_path: result.events_path, stderr_path: result.stderr_path, execution_result_path: "/redwright/output/codex-execution-result.json"}, null, 2) + "\\n")' "$final_status" "$codex_status" "$timed_out" "$has_diff" "$commit_sha" "$push_status" "$push_exit_status" "$validation_status" "$validation_command" "$validation_exit_status" "$validation_timed_out" "$branch" > /redwright/output/codex-execution-result.json
          if [ "$final_status" = codex_result_pushed ] || [ "$final_status" = codex_no_diff ]; then
            exit 0
          fi
          exit 1
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

        execution_result = codex_execution_result(output_directory)

        {
          "status" => execution_result.fetch("status") { status.success? ? "codex_executed" : "codex_execution_failed" },
          "image_name" => image_name,
          "stdout" => stdout,
          "stderr" => stderr,
          "exit_status" => status.exitstatus,
          "timed_out" => execution_result.fetch("timed_out", status.exitstatus == 124),
          "codex_prompt" => prompt_path,
          "codex_events" => File.join(File.expand_path(output_directory), "codex-events.jsonl"),
          "codex_stderr" => File.join(File.expand_path(output_directory), "codex-stderr.log"),
          "codex_last_message" => File.join(File.expand_path(output_directory), "codex-last-message.txt"),
          "codex_execution_result" => File.join(File.expand_path(output_directory), "codex-execution-result.json"),
          "post_codex_status" => File.join(File.expand_path(output_directory), "post-codex-status.txt"),
          "changed_files" => File.join(File.expand_path(output_directory), "changed-files.txt"),
          "git_diff" => File.join(File.expand_path(output_directory), "git-diff.patch"),
          "git_commit_log" => File.join(File.expand_path(output_directory), "git-commit.log"),
          "git_push_log" => File.join(File.expand_path(output_directory), "git-push.log"),
          "validation_stdout" => File.join(File.expand_path(output_directory), "validation-stdout.log"),
          "validation_stderr" => File.join(File.expand_path(output_directory), "validation-stderr.log"),
          "result_envelope" => File.join(File.expand_path(output_directory), "result-envelope.json"),
          "workspace_path" => File.join(File.expand_path(workspace_directory), "repo")
        }
      end

      def codex_execution_status(output_directory, process_status)
        result = codex_execution_result(output_directory)
        if result.key?("status")
          result.fetch("status")
        elsif process_status.success?
          "codex_executed"
        else
          "codex_execution_failed"
        end
      end

      def codex_execution_result(output_directory)
        result_path = File.join(output_directory, "codex-execution-result.json")
        return {} unless File.exist?(result_path)

        JSON.parse(File.read(result_path))
      rescue JSON::ParserError
        {}
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
