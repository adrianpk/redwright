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
      documents.reject(&:playbook?)
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

    def snapshot(path)
      target = root.join(path)
      return nil unless target.exist? || target.symlink?

      body = existing_path(path).read
      {body: body, revision: Digest::SHA256.hexdigest(body)}
    end

    # Generate first, then recheck all revisions before changing either file.
    def apply(changes, expected:)
      directory = root.join(".rw")
      raise Specifications::Error, "Invalid protocol lock directory." if directory.symlink?
      FileUtils.mkdir_p(directory)
      lock_path = directory.join("protocol.lock")
      raise Specifications::Error, "Invalid protocol lock file." if lock_path.symlink?
      File.open(lock_path, File::RDWR | File::CREAT, 0o600) do |lock|
        unless lock.flock(File::LOCK_EX | File::LOCK_NB)
          raise Specifications::Error.new("Protocol is being updated. Try again after it finishes.", code: :conflict)
        end
        originals = expected.to_h do |path, revision|
          original = snapshot(path)
          unless original&.fetch(:revision) == revision
            raise Specifications::Error.new("Protocol files changed while saving. Reload before trying again.", code: :conflict)
          end
          [path, original&.fetch(:body)]
        end
        changes.each_key { |path| validate_destination!(path) }
        applied = []
        begin
          changes.each do |path, body|
            target = root.join(path)
            if body.nil?
              target.delete
            else
              FileUtils.mkdir_p(target.dirname)
              File.atomic_write(target) { |file| file.write(body) }
            end
            applied << path
          end
        rescue SystemCallError
          applied.reverse_each do |path|
            if originals[path].nil?
              root.join(path).delete
            else
              File.atomic_write(root.join(path)) { |file| file.write(originals.fetch(path)) }
            end
          end
          raise Specifications::Error, "Could not save the protocol files."
        end
      ensure
        lock.flock(File::LOCK_UN)
      end
    end

    private

    def validate_destination!(path)
      raise Specifications::Error, "Invalid protocol filename." unless allowed_path?(path)
      target = root.join(path)
      ancestor = target.dirname
      ancestor = ancestor.parent until ancestor.exist?
      unless root.directory? && within_root?(ancestor.realpath) && !target.symlink? && (!target.exist? || target.file?)
        raise Specifications::Error, "Protocol file is outside the workspace."
      end
    end

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
