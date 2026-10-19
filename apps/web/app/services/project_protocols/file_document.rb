require "base64"
require "digest"

module ProjectProtocols
  class FileDocument
    include ActiveModel::Model

    attr_reader :store, :path, :position, :updated_at
    attr_accessor :body, :revision, :name, :description, :agents_revision, :index_revision, :collection

    def self.model_name
      ActiveModel::Name.new(self, nil, "ProtocolDocument")
    end

    def initialize(store:, path: nil, position: 0, collection: "protocols")
      @store = store
      @path = path
      @position = position
      @collection = path&.start_with?(".agents/playbooks/") ? "playbooks" : collection.presence || "protocols"
      if path
        reload
      else
        @name, @description, @body = "", "", ""
        @agents_revision = store.snapshot("AGENTS.md")&.fetch(:revision)
        @index_revision = store.snapshot(reference_index_path)&.fetch(:revision)
      end
    end

    def reload
      @body = store.root.join(path).read
      @revision = Digest::SHA256.hexdigest(body)
      @updated_at = store.root.join(path).mtime
      @name = File.basename(path, ".md")
      agents = store.snapshot("AGENTS.md")
      @agents_revision = agents&.fetch(:revision)
      index = store.snapshot(reference_index_path)
      @index_revision = index&.fetch(:revision)
      reference = index&.fetch(:body)&.lines&.find { |line| line.match?(/\A\s*[-*+]\s+`#{Regexp.escape(path)}`(?:\s|$)/) }
      @description = reference.to_s.split(/\s+—\s+/, 2)[1].to_s.strip
      self
    end

    def id
      return unless path
      Base64.urlsafe_encode64(path, padding: false)
    end

    def to_param
      id
    end

    def persisted?
      path.present?
    end

    def root?
      path == "AGENTS.md"
    end

    def key
      path == "AGENTS.md" ? "agents_root" : path.delete_prefix(".agents/").delete_suffix(".md").tr("/-", "__").downcase
    end

    def title
      return "AGENTS" if path == "AGENTS.md"
      return "PLAYBOOKS" if playbooks_index?

      path.delete_prefix(".agents/").delete_suffix(".md").split("/").map { |part| part.tr("_-", "  ").titleize }.join(" / ")
    end

    def layer
      path.start_with?(".agents/stacks/") ? "stack" : "behavioral"
    end

    def playbooks_index?
      path == ".agents/PLAYBOOKS.md"
    end

    def playbook?
      path.start_with?(".agents/playbooks/")
    end

    def reference_index?
      root? || playbooks_index?
    end

    def reference_index_path
      collection == "playbooks" ? ".agents/PLAYBOOKS.md" : "AGENTS.md"
    end

    def update(body:, revision:)
      errors.clear
      @body = body.to_s
      unless store.write(path, @body, revision: revision)
        errors.add(:base, :stale, message: "This file changed outside this editor. Reload it before saving.")
        return false
      end

      reload
      true
    end

    def destroy!
      store.delete(path)
    end

    def to_state
      {"key" => key, "path" => path, "title" => title, "layer" => layer,
       "position" => position, "body" => body,
       "provenance" => {"source" => "project_protocol_files", "source_path" => path}}
    end
  end
end
