# frozen_string_literal: true

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
          repo_url=$(ruby -rjson -e 'puts JSON.parse(File.read(ARGV.fetch(0))).fetch("repository_url")' "$packet")
          branch=$(ruby -rjson -e 'puts JSON.parse(File.read(ARGV.fetch(0))).fetch("result_branch")' "$packet")
          git clone "$repo_url" /redwright/workspace/repo
          cd /redwright/workspace/repo
          git checkout -B "$branch"
          git rev-parse HEAD > /redwright/output/checkout-revision.txt
          git status --short --branch > /redwright/output/checkout-status.txt
          ruby -rjson -e 'puts JSON.pretty_generate({status: "repository_cloned", repository_url: ARGV.fetch(0), result_branch: ARGV.fetch(1), checkout_revision: File.read("/redwright/output/checkout-revision.txt").strip, workspace_path: "/redwright/workspace/repo"})' "$repo_url" "$branch" > /redwright/output/clone-result.json
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
    end
  end
end
