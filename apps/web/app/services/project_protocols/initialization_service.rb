module ProjectProtocols
  class InitializationService
    def initialize(project:, workspace_path: nil, catalog: TemplateCatalog.new)
      @project = project
      @workspace_path = workspace_path
      @catalog = catalog
    end

    def call
      composition = Composer.new(project: @project, registry: @catalog).call
      metadata = {"initialized" => false, "stack_keys" => composition.stack_keys,
                  "fallback_used" => composition.fallback_used, "missing_stack_tokens" => composition.missing_stack_tokens}
      files = @workspace_path ? FileStore.new(root: @workspace_path) : @project.protocol_files
      unless files.root.directory?
        return metadata.merge("status" => "skipped", "reason" => "workspace_missing", "root_entrypoint" => "AGENTS.md", "files" => [])
      end

      # Existing files define the user's set, including deliberate omissions.
      if files.documents.empty? && !files.root.join(".redwright", "manifest.yml").file?
        composition.documents.each do |document|
          files.create(document.fetch("path"), document.fetch("body"))
        end
        metadata["initialized"] = true
      end

      metadata.merge("status" => "materialized", "workspace_path" => files.root.to_s,
       "root_entrypoint" => "AGENTS.md", "files" => files.documents.map { |document|
         {"path" => document.path, "title" => document.title, "absolute_path" => files.root.join(document.path).to_s}
       })
    end
  end
end
