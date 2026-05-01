# frozen_string_literal: true

require "coverage"
require "json"
require "fileutils"

Coverage.start

Dir[File.expand_path("../**/*_test.rb", __dir__)].sort.each do |path|
  require path
end

result = Coverage.result
files_total = 0
files_covered = 0
root = File.expand_path("../..", __dir__)
runtime_root = File.join(root, "lib", "redwright")
minimum_percent = ENV.fetch("COVERAGE_MIN_PERCENT", "51").to_f

result.each do |path, counts|
  next unless path.start_with?(runtime_root)
  next unless counts.is_a?(Array)

  executable_line_counts = counts.compact
  next if executable_line_counts.empty?

  files_total += 1
  files_covered += 1 if executable_line_counts.any?(&:positive?)
end

percent = if files_total.zero?
            0.0
          else
            ((files_covered.to_f / files_total) * 100).round(2)
          end

payload = {
  "name" => "coverage",
  "status" => percent >= minimum_percent ? "pass" : "fail",
  "minimum_file_percent" => minimum_percent,
  "metric" => "runtime_file_execution_percent",
  "line_percent" => percent,
  "files_total" => files_total,
  "files_covered" => files_covered
}

FileUtils.mkdir_p("tmp/quality")
File.write("tmp/quality/coverage.json", JSON.pretty_generate(payload) + "\n")
puts "quality:coverage percent=#{percent}"
abort("quality:coverage failed") if payload["status"] != "pass"
