require "base64"
require "digest"
require "fileutils"
require "active_support/core_ext/file/atomic"

module ProjectProtocols
  class FileStore
    def self.for_project(project)
      root = Pathname.new(project.root_path).expand_path
      if !root.directory? && project.repo_url.start_with?("local://")
        projects_root = ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"].presence ||
          (Rails.env.test? ? Rails.root.join("tmp", "redwright-local-projects") : Rails.root.join("..", "..", "_workspace", "Projects"))
        slug = root.basename.to_s.downcase.gsub(/[^a-z0-9._-]+/, "-").gsub(/\A-+|-+\z/, "")
        root = Pathname.new(projects_root).join(slug)
      end
      new(root: root)
    end

    attr_reader :root

    def initialize(root:)
      @root = Pathname.new(root).expand_path
    end

    def documents
      return [] unless root.directory?

      paths = ["AGENTS.md", *Dir.glob(".agents/**/*.md", File::FNM_DOTMATCH, base: root)]
      paths.select { |path| allowed_path?(path) && safe_file?(path) }
        .sort_by { |path| [path == "AGENTS.md" ? 0 : 1, path] }
        .each_with_index.map { |path, position| FileDocument.new(store: self, path: path, position: position) }
    end

    def top_level_entries
      entries = documents
      entries.any?(&:playbooks_index?) ? entries.reject(&:playbook?) : entries
    end

    def playbook_entries
      documents.select(&:playbook?)
    end

    def find(id)
      find_path(Base64.urlsafe_decode64(id.to_s))
    rescue ArgumentError
      raise ActiveRecord::RecordNotFound, "Protocol file not found."
    end

    def find_path(path)
      documents.find { |document| document.path == path } ||
        raise(ActiveRecord::RecordNotFound, "Protocol file not found.")
    end

    def state
      entries = documents
      {"status" => entries.any? ? "active" : "missing", "documents" => entries.map(&:to_state)}
    end

    def write(path, body, revision:)
      target = existing_path(path)
      return false unless Digest::SHA256.file(target).hexdigest == revision

      File.atomic_write(target) { |file| file.write(body) }
      true
    end

    def delete(path)
      File.delete(existing_path(path))
    end

    def create(path, body)
      raise ArgumentError, "Invalid protocol path." unless allowed_path?(path)

      target = root.join(path)
      ancestor = target.dirname
      ancestor = ancestor.parent until ancestor.exist?
      raise ArgumentError, "Protocol path is outside the workspace." unless root.directory? && within_root?(ancestor.realpath)

      FileUtils.mkdir_p(target.dirname)
      File.open(target, File::WRONLY | File::CREAT | File::EXCL, 0o644) { |file| file.write(body) }
      find_path(path)
    end

    private

    def existing_path(path)
      raise ActiveRecord::RecordNotFound, "Protocol file not found." unless allowed_path?(path) && safe_file?(path)

      root.join(path)
    end

    def allowed_path?(path)
      return false unless path.is_a?(String) && path.valid_encoding?
      return false if path.include?("\0") || path.include?("\\") || path.split("/").any? { |part| part == "." || part == ".." || part.empty? }
      path == "AGENTS.md" || (path.start_with?(".agents/") && path.end_with?(".md"))
    end

    def safe_file?(path)
      file = root.join(path)
      file.file? && within_root?(file.realpath)
    rescue Errno::ENOENT, Errno::ENOTDIR
      false
    end

    def within_root?(path)
      path == root.realpath || path.to_s.start_with?("#{root.realpath}/")
    end
  end
end
