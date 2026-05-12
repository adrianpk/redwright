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

        args.concat([image_name, "sh", "-lc", "test -f /redwright/input/packet.json && test -d /redwright/output"])

        stdout, stderr, status = command_runner.call(*args)

        {
          "status" => status.success? ? "container_started" : "docker_run_failed",
          "image_name" => image_name,
          "stdout" => stdout,
          "stderr" => stderr,
          "exit_status" => status.exitstatus
        }
      end
    end
  end
end
