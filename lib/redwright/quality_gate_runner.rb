# frozen_string_literal: true

require "open3"

module Redwright
  QualityCheckResult = Struct.new(
    :name, :status, :command, :stdout, :stderr, :error_message, :exit_code,
    keyword_init: true
  )

  class QualityGateRunner
    DEFAULT_TIMEOUT_MS = 120_000

    def run(project_path:, lint_command:, test_command:, timeout_ms: DEFAULT_TIMEOUT_MS)
      results = []
      if non_empty?(lint_command)
        results << run_check(
          name: "lint",
          command: lint_command,
          project_path: project_path,
          timeout_ms: timeout_ms
        )
      end
      if non_empty?(test_command)
        results << run_check(
          name: "test",
          command: test_command,
          project_path: project_path,
          timeout_ms: timeout_ms
        )
      end
      results
    end

    private

    def run_check(name:, command:, project_path:, timeout_ms:)
      seconds = [(timeout_ms.to_f / 1000.0), 0.1].max.to_s
      stdout, stderr, status = Open3.capture3(
        "timeout",
        "--preserve-status",
        seconds,
        "sh",
        "-lc",
        command,
        chdir: project_path
      )
      if [124, 137, 143].include?(status.exitstatus)
        return QualityCheckResult.new(
          name: name,
          status: "error",
          command: command,
          stdout: stdout,
          stderr: stderr,
          error_message: "quality_check_timeout",
          exit_code: status.exitstatus
        )
      end
      if status.success?
        return QualityCheckResult.new(
          name: name,
          status: "ok",
          command: command,
          stdout: stdout,
          stderr: stderr,
          error_message: nil,
          exit_code: 0
        )
      end

      QualityCheckResult.new(
        name: name,
        status: "error",
        command: command,
        stdout: stdout,
        stderr: stderr,
        error_message: "quality_check_failed",
        exit_code: status.exitstatus
      )
    rescue StandardError => e
      QualityCheckResult.new(
        name: name,
        status: "error",
        command: command,
        stdout: "",
        stderr: "",
        error_message: e.message,
        exit_code: nil
      )
    end

    def non_empty?(value)
      value.is_a?(String) && !value.strip.empty?
    end
  end
end
