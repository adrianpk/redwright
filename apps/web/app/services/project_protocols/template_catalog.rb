require "fileutils"

module ProjectProtocols
  class TemplateCatalog
    TemplateSet = Struct.new(:key, :files, keyword_init: true) do
      def common?
        key == "common"
      end

      def name
        common? ? "Common Protocol Templates" : "#{key.tr("-_", " ").titleize} Protocol Templates"
      end

      def documents
        files.documents
      end

      def to_param
        key
      end
    end

    def initialize(root: nil)
      @root = Pathname.new(root || Rails.configuration.x.protocols.template_root || Rails.root.join("app", "protocol_templates", "default_behavioral"))
    end

    def common_template
      TemplateSet.new(key: "common", files: FileStore.new(root: root))
    end

    def common_documents
      common_template.documents.reject { |document| document.path.start_with?(".agents/stacks/") }.map(&:to_state)
    end

    def stack_template_sets
      return [] unless stacks_root.directory?

      stacks_root.children.select(&:directory?).sort.map do |path|
        key = path.basename.to_s
        TemplateSet.new(key: key, files: FileStore.new(root: root, prefix: ".agents/stacks/#{key}"))
      end
    end

    def stack_templates
      stack_template_sets.index_with do |template|
        {"stack_key" => template.key, "matchers" => [template.key], "documents" => template.documents.map(&:to_state)}
      end.transform_keys(&:key)
    end

    def available_stack_keys
      stack_template_sets.map(&:key)
    end

    def find_template(key)
      return common_template if key.to_s == "common"

      stack_template_sets.find { |template| template.key == key.to_s } ||
        raise(ActiveRecord::RecordNotFound, "Protocol template not found.")
    end

    def create_stack_template!(stack_key:)
      key = stack_key.to_s.strip.downcase
      raise ArgumentError, "Stack identity must contain letters, numbers, hyphens or underscores." unless /\A[a-z0-9][a-z0-9_-]*\z/.match?(key)
      raise ArgumentError, "Stack identity is reserved." if key == "common"
      raise ArgumentError, "Stack identity already exists." if stacks_root.join(key).exist?

      ancestor = stacks_root
      ancestor = ancestor.parent until ancestor.exist?
      unless ancestor.realpath == root.realpath || ancestor.realpath.to_s.start_with?("#{root.realpath}/")
        raise ArgumentError, "Stack templates must stay inside the template directory."
      end
      FileUtils.mkdir_p(stacks_root)
      Dir.mkdir(stacks_root.join(key))
      find_template(key)
    end

    private

    attr_reader :root

    def stacks_root
      root.join(".agents", "stacks")
    end
  end
end
