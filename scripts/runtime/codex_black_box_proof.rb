#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))

require "redwright/codex_proof/harness"
require "redwright/codex_proof/container_smoke"

options = {
  runs_root: File.expand_path("../../tmp/codex-proof/runs", __dir__),
  dockerfile: File.expand_path("../../runtime/codex-proof/go/Dockerfile", __dir__),
  context_dir: File.expand_path("../../runtime/codex-proof/go", __dir__),
  image_name: Redwright::CodexProof::ContainerSmoke::DEFAULT_IMAGE_NAME,
  smoke: false,
  clone: false,
  preflight: false,
  codex_exec: false
}

parser = OptionParser.new do |opts|
  opts.banner = "usage: scripts/runtime/codex_black_box_proof.rb --packet PATH [--runs-root PATH]"
  opts.on("--packet PATH", "Path to the proof input packet JSON file") { |value| options[:packet] = value }
  opts.on("--runs-root PATH", "Directory where proof run directories are created") { |value| options[:runs_root] = value }
  opts.on("--smoke", "Build and run the placeholder Docker smoke test after preparing the run") { options[:smoke] = true }
  opts.on("--clone", "Build and run the Docker repository clone proof after preparing the run") { options[:clone] = true }
  opts.on("--preflight", "Build and run Codex plus remote credential preflight") { options[:preflight] = true }
  opts.on("--codex-exec", "Build and run the non-interactive Codex proof task") { options[:codex_exec] = true }
  opts.on("--dockerfile PATH", "Path to the proof Dockerfile") { |value| options[:dockerfile] = value }
  opts.on("--context-dir PATH", "Path to the proof Docker build context") { |value| options[:context_dir] = value }
  opts.on("--image-name NAME", "Docker image name to build and run") { |value| options[:image_name] = value }
end

parser.parse!(ARGV)

unless options[:packet]
  warn(parser.to_s)
  exit 2
end

packet = Redwright::CodexProof::InputPacket.from_json_file(options.fetch(:packet))
result = Redwright::CodexProof::Harness.new(
  packet: packet,
  runs_root: options.fetch(:runs_root)
).prepare

if result.fetch("status") == "prepared" && (options.fetch(:smoke) || options.fetch(:clone) || options.fetch(:preflight) || options.fetch(:codex_exec))
  smoke = Redwright::CodexProof::ContainerSmoke.new(
    dockerfile: options.fetch(:dockerfile),
    context_dir: options.fetch(:context_dir),
    image_name: options.fetch(:image_name)
  )
  build_result = smoke.build_image
  run_result = nil
  if build_result.fetch("status") == "built" && options.fetch(:smoke)
    run_result = smoke.run_container(
      input_packet: result.fetch("input_packet"),
      output_directory: result.fetch("output_directory"),
      env: { "RW_PROOF_MODE" => "smoke" }
    )
  end
  if build_result.fetch("status") == "built" && options.fetch(:clone)
    run_result = smoke.clone_repository(
      input_packet: result.fetch("input_packet"),
      output_directory: result.fetch("output_directory"),
      workspace_directory: result.fetch("workspace_directory"),
      env: { "RW_PROOF_MODE" => "clone" }
    )
  end
  if build_result.fetch("status") == "built" && options.fetch(:preflight)
    runtime_env = {
      "CODEX_API_KEY" => ENV.fetch("CODEX_API_KEY", ""),
      "OPENAI_API_KEY" => ENV.fetch("OPENAI_API_KEY", ""),
      "CODEBERG_PUSH_TOKEN" => ENV.fetch("CODEBERG_PUSH_TOKEN", "")
    }.reject { |_key, value| value.to_s.empty? }
    run_result = smoke.preflight_credentials(
      output_directory: result.fetch("output_directory"),
      env: runtime_env
    )
  end
  if build_result.fetch("status") == "built" && options.fetch(:codex_exec)
    runtime_env = {
      "CODEX_API_KEY" => ENV.fetch("CODEX_API_KEY", ""),
      "OPENAI_API_KEY" => ENV.fetch("OPENAI_API_KEY", ""),
      "CODEBERG_PUSH_TOKEN" => ENV.fetch("CODEBERG_PUSH_TOKEN", ""),
      "CODEBERG_PUSH_USER" => ENV.fetch("CODEBERG_PUSH_USER", "")
    }.reject { |_key, value| value.to_s.empty? }
    run_result = smoke.execute_codex_task(
      input_packet: result.fetch("input_packet"),
      output_directory: result.fetch("output_directory"),
      workspace_directory: result.fetch("workspace_directory"),
      env: runtime_env
    )
  end

  result = result.merge(
    "container_build" => build_result,
    "container_run" => run_result
  )
end

puts(JSON.pretty_generate(result))
container_run = result["container_run"]
if container_run
  successful_statuses = %w[container_started repository_cloned preflight_passed codex_executed codex_no_diff codex_result_pushed]
  exit(successful_statuses.include?(container_run.fetch("status")) ? 0 : 2)
end

exit(result.fetch("status") == "prepared" ? 0 : 2)
