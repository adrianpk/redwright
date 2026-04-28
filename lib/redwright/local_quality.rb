# frozen_string_literal: true

require "json"
require "time"
require "open3"
require "fileutils"

module Redwright
  class LocalQuality
    START_MARKER = "<!-- REDWRIGHT_LOCAL_BADGES:START -->"
    END_MARKER = "<!-- REDWRIGHT_LOCAL_BADGES:END -->"

    def run_step(name:, command:)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      _out, _err, status = Open3.capture3(command)
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).to_i

      {
        name: name,
        status: status.success? ? "pass" : "fail",
        timestamp: Time.now.utc.iso8601(6),
        command: command,
        exit_code: status.exitstatus || 1,
        duration_ms: duration_ms
      }
    end

    def write_artifact(path:, payload:)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, JSON.pretty_generate(payload) + "\n")
    end

    def read_artifact(path:)
      JSON.parse(File.read(path))
    end

    def build_summary(lint:, test:)
      status = if lint["status"] == "pass" && test["status"] == "pass"
                 "pass"
               else
                 "fail"
               end

      {
        name: "summary",
        status: status,
        timestamp: Time.now.utc.iso8601(6),
        command: "quality:all",
        exit_code: status == "pass" ? 0 : 1,
        duration_ms: lint["duration_ms"].to_i + test["duration_ms"].to_i,
        checks: [
          { name: lint["name"], status: lint["status"] },
          { name: test["name"], status: test["status"] }
        ]
      }
    end

    def render_readme_badges(readme_path:, lint:, test:, summary:)
      section = [
        START_MARKER,
        "## Local Quality Badges",
        "",
        "| Check | Status | Color |",
        "|---|---|---|",
        "| lint | #{lint['status'].upcase} | #{color_for(lint['status'])} |",
        "| test | #{test['status'].upcase} | #{color_for(test['status'])} |",
        "| summary | #{summary['status'].upcase} | #{color_for(summary['status'])} |",
        END_MARKER
      ].join("\n")

      current = File.exist?(readme_path) ? File.read(readme_path) : ""
      updated = if current.include?(START_MARKER) && current.include?(END_MARKER)
                  current.sub(/#{Regexp.escape(START_MARKER)}.*?#{Regexp.escape(END_MARKER)}/m, section)
                else
                  [current.rstrip, "", section, ""].join("\n")
                end
      File.write(readme_path, updated)
    end

    private

    def color_for(status)
      case status
      when "pass" then "green"
      when "fail" then "red"
      else "yellow"
      end
    end
  end
end
