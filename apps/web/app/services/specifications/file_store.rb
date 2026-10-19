require "yaml"
require "digest"
require "json"
require "date"
require "fileutils"
require "active_support/core_ext/file/atomic"

module Specifications
  class FileStore
    MAX_BYTES = 2 * 1024 * 1024
    MAX_FILES = 500
    MAX_TOTAL_BYTES = 32 * 1024 * 1024
    PATTERNS = %w[ops/*/spec/**/artifact.md ops/*/tracker/**/artifact.md ops/*/report/**/artifact.md ops/specs/specs/**/*.md ops/specs/drafts/**/*.md ops/plans/**/*.md ops/trackers/**/*.md].freeze
    attr_reader :project, :root

    def initialize(project, root: nil)
      @project = project
      @root = root.present? ? Pathname.new(root).expand_path : ProjectProtocols::FileStore.for_project(project).root
    end

    def entries(patterns: PATTERNS)
      ensure_workspace!
      paths = patterns.flat_map { |pattern| Dir.glob(pattern, base: root) }.uniq.sort
      raise Error, "This project has too many specification files to index." if paths.size > MAX_FILES
      total = paths.sum { |path| safe_path(path).size }
      raise Error, "The project specification collection is too large." if total > MAX_TOTAL_BYTES
      paths.map { |path| read(path) }
    end

    def read(path)
      target = safe_path(path)
      raise Error, "Document file is too large: #{path}" if target.size > MAX_BYTES
      raw = target.read(encoding: "UTF-8")
      raise Error, "Document is not valid UTF-8: #{path}" unless raw.valid_encoding?
      metadata, body = split(raw, path)
      if metadata.key?("title") && (!metadata["title"].is_a?(String) || metadata["title"].strip.empty?)
        raise Error, "Document title is invalid: #{path}"
      end
      relations = metadata["relations"]
      if relations && (!relations.is_a?(Array) || relations.any? { |edge| !edge.is_a?(Hash) || !edge["path"].is_a?(String) || !DocumentRelation::RELATION_TYPES.include?(edge["type"]) })
        raise Error, "Document relations are invalid: #{path}"
      end
      kind = if path.include?("/dump/")
        "dump"
      elsif path.include?("/ticket/")
        "ticket"
      elsif path.include?("/report/")
        "internal"
      elsif path.match?(%r{(?:/tracker/|\Aops/(?:plans|trackers)/)})
        "plan_tracker"
      else
        "spec"
      end
      raise Error, "Document body is empty: #{path}" if !%w[ticket dump].include?(kind) && body.blank?
      status = metadata.fetch("status", kind == "plan_tracker" ? "tracking" : "draft").to_s
      if kind == "spec" && !%w[draft approved accepted final].include?(status)
        raise Error, "Unknown specification status in #{path}."
      end
      raise Error, "Unknown dump status in #{path}." if kind == "dump" && !Dump::STATUSES.include?(status)
      case_slug = metadata["case_slug"].to_s
      use_case = project.use_cases.find_by(slug: case_slug) if case_slug.present?
      raise Error, "Unknown use case in #{path}." if case_slug.present? && !use_case
      {
        path: path, body: body, metadata: metadata, artifact_type: kind,
        title: metadata["title"].presence || body.lines.find { |line| line.start_with?("# ") }&.delete_prefix("# ")&.strip || File.basename(path, ".md"),
        status: status, use_case_id: use_case&.id,
        source_hash: Digest::SHA256.hexdigest(raw), source_modified_at: target.mtime.utc
      }
    rescue Psych::Exception, EncodingError, ArgumentError => e
      raise Error, "Invalid document #{path}: #{e.message}"
    end

    def write(path:, metadata:, body:, revision: nil)
      ensure_workspace!
      raise Error, "Document body is too large." if body.to_s.bytesize > MAX_BYTES
      with_lock do
        path ||= next_path(metadata.fetch("title"), metadata.fetch("artifact_type", "spec"))
        target = safe_path(path, creating: true)
        if target.exist?
          actual = Digest::SHA256.file(target).hexdigest
          raise Error.new("The file changed. Reload it before saving.", code: :conflict) unless revision == actual
        elsif revision.present?
          raise Error.new("The file was removed. Reload before saving.", code: :conflict)
        end
        FileUtils.mkdir_p(target.dirname)
        persisted = metadata.except("artifact_type")
        content = persisted.to_yaml + "---\n\n" + body.to_s
        raise Error, "Document is too large." if content.bytesize > MAX_BYTES
        File.atomic_write(target) { |file| file.write(content) }
        write_envelope(path, persisted) if File.basename(path) == "artifact.md"
        read(path)
      end
    end

    def add_relation(document, target, relation_type)
      entry = read(document.relative_path)
      relations = Array(entry[:metadata]["relations"]) | [{"path" => target.relative_path, "type" => relation_type}]
      write(path: entry[:path], metadata: entry[:metadata].merge("relations" => relations), body: entry[:body], revision: entry[:source_hash])
    end

    private

    def ensure_workspace!
      raise Error, "The project workspace is unavailable." unless root.directory?
    end

    def safe_path(path, creating: false)
      ensure_workspace!
      parts = path.to_s.split("/")
      unless path.is_a?(String) && path.start_with?("ops/") && path.end_with?(".md") && !path.include?("\\") && !path.include?("\0") && parts.none? { |part| part.empty? || %w[. ..].include?(part) }
        raise Error, "Invalid document path."
      end
      target = root.join(path)
      ancestor = target
      ancestor = ancestor.parent until ancestor.exist? || ancestor.symlink?
      resolved = ancestor.realpath
      unless resolved == root.realpath || resolved.to_s.start_with?("#{root.realpath}/")
        raise Error, "Document path escapes the project workspace."
      end
      raise Error, "Document file is missing: #{path}" unless creating || target.file?
      target
    rescue Errno::ENOENT, Errno::ENOTDIR, Errno::EACCES => e
      raise Error, "Cannot access document: #{e.class.name}"
    end

    def split(raw, path)
      return [{}, raw] unless raw.start_with?("---\n", "---\r\n")
      match = raw.match(/\A---\r?\n(.*?)\r?\n---\r?\n?(.*)\z/m)
      raise Error, "Unclosed document metadata: #{path}" unless match
      metadata = YAML.safe_load(match[1], permitted_classes: [Time, Date], aliases: false)
      raise Error, "Document metadata must be a mapping: #{path}" unless metadata.is_a?(Hash)
      [metadata.stringify_keys, match[2].sub(/\A\r?\n/, "")]
    end

    def with_lock
      directory = root.join(".rw")
      raise Error, "Invalid workspace lock directory." if directory.exist? && directory.realpath != root.realpath.join(".rw")
      FileUtils.mkdir_p(directory)
      path = directory.join("specifications.lock")
      raise Error, "Invalid workspace lock file." if path.symlink?
      File.open(path, File::RDWR | File::CREAT, 0o600) do |lock|
        lock.flock(File::LOCK_EX)
        yield
      ensure
        lock.flock(File::LOCK_UN) if lock
      end
    end

    def next_path(title, kind)
      slug = title.to_s.parameterize[0, 80].presence || "spec"
      directory = {"spec" => "spec", "plan_tracker" => "tracker", "internal" => "report", "ticket" => "ticket", "dump" => "dump"}.fetch(kind)
      parent = root.join("ops", "default", directory)
      ordinal = Dir.glob("*", base: parent).filter_map { |name| name[/\A\d+/]&.to_i }.max.to_i + 1
      "ops/default/#{directory}/#{format('%05d', ordinal)}-#{slug}/artifact.md"
    end

    def write_envelope(path, metadata)
      directory = root.join(path).dirname
      envelope = directory.join("metadata.json")
      raise Error, "Invalid artifact metadata path." if envelope.symlink?
      return if envelope.exist?
      value = {
        schema_version: "ops-layout/v1", id: directory.basename.to_s,
        type: path.split("/")[2], namespace: path.split("/")[1],
        title: metadata["title"], status: "created", revision: 1,
        created_at: metadata["created_at"], updated_at: metadata["created_at"],
        producer: {name: "redwright", version: "unversioned"}, external_ids: [],
        sources: [], continuations: [], files: ["artifact.md"]
      }
      File.atomic_write(envelope) { |file| file.write(JSON.pretty_generate(value) + "\n") }
    end
  end
end
