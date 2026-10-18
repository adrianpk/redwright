require "base64"
require "digest"

module ProjectProtocols
  class FileDocument
    include ActiveModel::Model

    attr_reader :store, :path, :position, :updated_at
    attr_accessor :body, :revision

    def self.model_name
      ActiveModel::Name.new(self, nil, "ProtocolDocument")
    end

    def initialize(store:, path:, position: 0)
      @store = store
      @path = path
      @position = position
      reload
    end

    def reload
      @body = store.root.join(path).read
      @revision = Digest::SHA256.hexdigest(body)
      @updated_at = store.root.join(path).mtime
      self
    end

    def id
      Base64.urlsafe_encode64(path, padding: false)
    end

    def to_param
      id
    end

    def persisted?
      true
    end

    def key
      path == "AGENTS.md" ? "agents_root" : path.delete_prefix(".agents/").delete_suffix(".md").tr("/-", "__").downcase
    end

    def title
      return "AGENTS" if path == "AGENTS.md"

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
