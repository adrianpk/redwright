# frozen_string_literal: true

require "coverage"
require "json"
require "fileutils"

# Prevent minitest/autorun from running automatically while files are required.
ENV["MT_NO_AUTORUN"] = "1"
require "minitest"

Coverage.start

Dir[File.expand_path("../**/*_test.rb", __dir__)].sort.each do |path|
  require path
end

tests_ok = Minitest.run

result = Coverage.result
lines_total = 0
lines_covered = 0
root = File.expand_path("../..", __dir__)
runtime_root = File.join(root, "lib", "redwright")
minimum_percent = ENV.fetch("COVERAGE_MIN_PERCENT", "25").to_f

result.each do |path, counts|
  next unless path.start_with?(runtime_root)
  next unless counts.is_a?(Array)

  counts.each do |count|
    next if count.nil?

    lines_total += 1
    lines_covered += 1 if count.positive?
  end
end

percent = if lines_total.zero?
            0.0
          else
            ((lines_covered.to_f / lines_total) * 100).round(2)
          end

payload = {
  "name" => "coverage",
  "status" => tests_ok && percent >= minimum_percent ? "pass" : "fail",
  "minimum_line_percent" => minimum_percent,
  "metric" => "runtime_line_coverage_percent",
  "line_percent" => percent,
  "lines_total" => lines_total,
  "lines_covered" => lines_covered
}

FileUtils.mkdir_p("tmp/quality")
File.write("tmp/quality/coverage.json", JSON.pretty_generate(payload) + "\n")
puts "quality:coverage percent=#{percent}"
abort("quality:coverage failed") if payload["status"] != "pass"
