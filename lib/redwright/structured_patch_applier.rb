# frozen_string_literal: true

require "fileutils"

module Redwright
  class StructuredPatchApplier
    def self.structured_patch?(patch)
      patch.to_s.lines.first.to_s.strip == "*** Begin Patch"
    end

    def apply(project_root:, patch:)
      operations = parse(patch)
      operations.each do |operation|
        case operation.fetch(:type)
        when :update
          apply_update(project_root: project_root, path: operation.fetch(:path), hunks: operation.fetch(:hunks))
        when :add
          apply_add(project_root: project_root, path: operation.fetch(:path), lines: operation.fetch(:lines))
        else
          raise RuntimeError, "unsupported_apply_patch_operation: #{operation.fetch(:type)}"
        end
      end
      { stdout: "applied structured patch\n", stderr: "" }
    end

    private

    def parse(patch)
      lines = patch.to_s.lines.map(&:chomp)
      raise RuntimeError, "invalid_apply_patch" unless lines.shift.to_s.strip == "*** Begin Patch"

      operations = []
      current = nil
      current_hunk = nil

      lines.each do |line|
        marker = line.strip
        case marker
        when /\A\*\*\* Update File: (.+)\z/
          operations << current if current
          current = {type: :update, path: Regexp.last_match(1), hunks: []}
          current_hunk = nil
        when /\A\*\*\* Add File: (.+)\z/
          operations << current if current
          current = {type: :add, path: Regexp.last_match(1), lines: []}
          current_hunk = nil
        when /\A\*\*\* (Delete File|Move to): /
          raise RuntimeError, "unsupported_apply_patch_operation: #{Regexp.last_match(1).downcase.tr(' ', '_')}"
        when "*** End Patch"
          break
        when /\A@@/
          raise RuntimeError, "apply_patch_hunk_without_file" unless current && current.fetch(:type) == :update

          current_hunk = []
          current.fetch(:hunks) << current_hunk
        else
          raise RuntimeError, "apply_patch_content_without_file" unless current

          if current.fetch(:type) == :add
            raise RuntimeError, "invalid_add_file_line" unless line.start_with?("+")

            current.fetch(:lines) << line.delete_prefix("+")
          else
            current_hunk ||= []
            current.fetch(:hunks) << current_hunk if current.fetch(:hunks).empty? || current.fetch(:hunks).last != current_hunk
            current_hunk << line unless line.start_with?("\\")
          end
        end
      end
      operations << current if current
      operations
    end

    def apply_update(project_root:, path:, hunks:)
      full_path = safe_path(project_root, path)
      content = File.exist?(full_path) ? File.read(full_path) : ""
      trailing_newline = content.end_with?("\n")
      lines = content.lines(chomp: true)
      cursor = 0

      hunks.each do |hunk|
        old_lines = hunk.filter_map { |line| old_line(line) }
        new_lines = hunk.filter_map { |line| new_line(line) }
        index = find_subsequence(lines, old_lines, cursor) || find_subsequence(lines, old_lines, 0)
        raise RuntimeError, "apply_patch_context_not_found: #{path}" unless index

        lines[index, old_lines.length] = new_lines
        cursor = index + new_lines.length
      end

      File.write(full_path, lines.join("\n") + (trailing_newline || lines.any? ? "\n" : ""))
    end

    def apply_add(project_root:, path:, lines:)
      full_path = safe_path(project_root, path)
      raise RuntimeError, "apply_patch_file_exists: #{path}" if File.exist?(full_path)

      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, lines.join("\n") + "\n")
    end

    def old_line(line)
      return line[1..] if line.start_with?(" ", "-")

      nil
    end

    def new_line(line)
      return line[1..] if line.start_with?(" ", "+")

      nil
    end

    def find_subsequence(lines, subsequence, start_index)
      return start_index if subsequence.empty?

      max = lines.length - subsequence.length
      index = start_index
      while index <= max
        return index if lines[index, subsequence.length] == subsequence

        index += 1
      end
      nil
    end

    def safe_path(project_root, raw_path)
      root = File.expand_path(project_root)
      candidate = File.expand_path(raw_path.to_s, root)
      return candidate if candidate == root
      return candidate if candidate.start_with?("#{root}/")

      raise ArgumentError, "path_outside_project_root"
    end
  end
end
