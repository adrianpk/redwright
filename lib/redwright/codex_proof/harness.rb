# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "securerandom"
require "time"

require_relative "input_packet"

module Redwright
  module CodexProof
    class Harness
      attr_reader :packet, :runs_root, :clock, :id_generator

      def initialize(packet:, runs_root:, clock: Time, id_generator: -> { SecureRandom.hex(4) })
        @packet = packet
        @runs_root = runs_root
        @clock = clock
        @id_generator = id_generator
      end

      def prepare
        unless packet.valid?
          return {
            "status" => "invalid_input",
            "errors" => packet.errors
          }
        end

        FileUtils.mkdir_p(runs_root)
        FileUtils.mkdir_p(input_dir)
        FileUtils.mkdir_p(output_dir)

        File.write(packet_path, JSON.pretty_generate(run_packet) + "\n")

        {
          "status" => "prepared",
          "run_id" => run_id,
          "run_directory" => run_dir,
          "input_packet" => packet_path,
          "output_directory" => output_dir
        }
      end

      private

      def run_packet
        packet.to_h.merge(
          "run_id" => run_id,
          "run_directory" => run_dir,
          "output_directory" => output_dir
        )
      end

      def run_id
        @run_id ||= "codex-proof-#{clock.now.utc.strftime("%Y%m%d%H%M%S")}-#{id_generator.call}"
      end

      def run_dir
        @run_dir ||= File.expand_path(run_id, runs_root)
      end

      def input_dir
        File.join(run_dir, "input")
      end

      def output_dir
        @output_dir ||= begin
          requested = packet.to_h.fetch("output_directory")
          if Pathname.new(requested).absolute?
            requested
          else
            File.expand_path(requested, run_dir)
          end
        end
      end

      def packet_path
        File.join(input_dir, "packet.json")
      end
    end
  end
end
