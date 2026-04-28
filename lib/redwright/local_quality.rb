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

    def render_readme_badges(readme_path:, lint:, test:, summary:, coverage: nil)
      coverage_value = coverage && coverage["line_percent"] ? "#{coverage["line_percent"]}%" : "n/a"
      coverage_status = coverage && coverage["status"] ? coverage["status"] : "unknown"
      ci_message = status_message(summary["status"])
      ci_color = shields_color(summary["status"])
      coverage_color = shields_color(coverage_status)

      section = [
        START_MARKER,
        "[![CI](https://img.shields.io/badge/CI-#{ci_message}-#{ci_color})](https://codeberg.org/adrianpk/redwright)",
        "[![coverage](https://img.shields.io/badge/coverage-#{coverage_value}-#{coverage_color})](badges/coverage.svg)",
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

    def write_svg_badge(path:, label:, status:, message: nil)
      FileUtils.mkdir_p(File.dirname(path))
      color = color_for(status)
      message ||= status.to_s
      svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="160" height="20" role="img" aria-label="#{label}: #{message}">
          <linearGradient id="s" x2="0" y2="100%">
            <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
            <stop offset="1" stop-opacity=".1"/>
          </linearGradient>
          <rect rx="3" width="160" height="20" fill="#555"/>
          <rect rx="3" x="72" width="88" height="20" fill="#{badge_hex(color)}"/>
          <path fill="#{badge_hex(color)}" d="M72 0h4v20h-4z"/>
          <rect rx="3" width="160" height="20" fill="url(#s)"/>
          <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" font-size="11">
            <text x="36" y="15">#{label}</text>
            <text x="116" y="15">#{message}</text>
          </g>
        </svg>
      SVG
      File.write(path, svg)
    end

    def badge_hex(color)
      case color
      when "green" then "#4c1"
      when "red" then "#e05d44"
      else "#dfb317"
      end
    end

    def status_message(status)
      status == "pass" ? "passing" : "failing"
    end

    def shields_color(status)
      case status
      when "pass" then "brightgreen"
      when "fail" then "red"
      else "yellow"
      end
    end
  end
end
