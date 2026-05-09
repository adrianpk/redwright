require Rails.root.join("..", "..", "lib", "redwright", "llm", "context_policy").expand_path.to_s

module AgentTicketExecution
  module ContextSectionProviders
    MAX_FILE_BYTES = 32_000
    MAX_TREE_ENTRIES = 300
    RELEVANT_FILE_EXTENSIONS = %w[.go .rb .js .ts .tsx .jsx .py .rs .zig .ex .exs .java .kt .cs .php].freeze
    RELEVANT_FILE_NAMES = %w[
      go.mod go.sum Gemfile Gemfile.lock package.json pnpm-lock.yaml yarn.lock package-lock.json
      mix.exs Cargo.toml build.gradle pom.xml Dockerfile Makefile README.md
    ].freeze
    TEST_FILE_PATTERNS = [
      /_test\./,
      /\.test\./,
      /_spec\./,
      /\.spec\./,
      %r{\Atest/},
      %r{\Aspec/}
    ].freeze
    SKIPPED_DIRECTORIES = %w[.git node_modules vendor tmp log coverage dist build target .next].freeze
    PROTOCOL_FILE_PATTERNS = [
      %r{\AAGENTS\.md\z},
      %r{\A\.agents/}
    ].freeze

    Context = Struct.new(:ticket, :project, :request, :workspace_path, keyword_init: true)

    class Base
      private

      def section(name, content, authority)
        Redwright::LLM::ContextSection.new(
          name: name,
          content: content,
          authority: authority,
          metadata: section_metadata(content)
        )
      end

      def section_metadata(content)
        case content
        when Array
          {"entries" => content.length}
        when Hash
          {"keys" => content.keys.map(&:to_s)}
        else
          {}
        end
      end
    end

    class TicketProject < Base
      def sections(context)
        [
          section("ticket", ticket_payload(context.ticket, context.request), "ticket_record"),
          section("project", project_payload(context.project), "project_record")
        ]
      end

      private

      def ticket_payload(ticket, request)
        {
          "id" => ticket.id,
          "ticket_key" => ticket.ticket_key,
          "display_key" => ticket.display_key,
          "title" => ticket.title,
          "description" => ticket.description,
          "assignee" => ticket.assignee,
          "priority" => ticket.priority,
          "workflow_status" => ticket.workflow_status,
          "kind" => ticket.kind,
          "severity" => ticket.severity,
          "scope" => ticket.scope,
          "source" => ticket.source,
          "request" => {
            "mode" => request.fetch("mode"),
            "ticket_ref" => request["ticket_ref"],
            "branch_name" => request["branch_name"],
            "source_channel" => request["source_channel"],
            "actor_identifier" => request["actor_identifier"]
          }
        }
      end

      def project_payload(project)
        {
          "id" => project.id,
          "name" => project.name,
          "description" => project.description,
          "root_path" => project.root_path,
          "repo_url" => project.repo_url,
          "stack_slug" => project.stack_slug,
          "attributes" => project.project_attributes_scope.map do |attribute|
            {
              "key" => attribute.key,
              "value" => attribute.value,
              "source" => attribute.source,
              "weight" => attribute.weight
            }
          end
        }
      end
    end

    class Repository < Base
      def sections(context)
        files = repository_files(context.workspace_path)

        [
          section("repository_tree", repository_tree_payload(files), "workspace_filesystem"),
          section("relevant_files", file_payload(context.workspace_path, relevant_files(files)), "workspace_filesystem"),
          section("tests", file_payload(context.workspace_path, test_files(files)), "workspace_filesystem")
        ]
      end

      private

      def repository_tree_payload(files)
        {
          "entries" => files.first(MAX_TREE_ENTRIES).map do |file|
            {"path" => file.fetch(:path), "type" => "file", "bytes" => file.fetch(:bytes)}
          end,
          "truncated" => files.length > MAX_TREE_ENTRIES,
          "total_files" => files.length
        }
      end

      def file_payload(workspace_path, files)
        files.map do |file|
          full_path = File.join(workspace_path, file.fetch(:path))
          {
            "path" => file.fetch(:path),
            "content" => read_file(full_path),
            "truncated" => file.fetch(:bytes) > MAX_FILE_BYTES
          }
        end
      end

      def relevant_files(files)
        files.select do |file|
          path = file.fetch(:path)
          RELEVANT_FILE_NAMES.include?(File.basename(path)) || RELEVANT_FILE_EXTENSIONS.include?(File.extname(path))
        end
      end

      def test_files(files)
        files.select do |file|
          TEST_FILE_PATTERNS.any? { |pattern| pattern.match?(file.fetch(:path)) }
        end
      end

      def repository_files(workspace_path)
        root = workspace_path.to_s
        return [] unless File.directory?(root)

        Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).filter_map do |path|
          next unless File.file?(path)

          relative = path.delete_prefix("#{root}/")
          next if skipped_path?(relative)
          next if protocol_path?(relative)

          {path: relative, bytes: File.size(path)}
        end.sort_by { |file| file.fetch(:path) }
      end

      def skipped_path?(relative_path)
        relative_path.split(File::SEPARATOR).any? { |part| SKIPPED_DIRECTORIES.include?(part) }
      end

      def protocol_path?(relative_path)
        PROTOCOL_FILE_PATTERNS.any? { |pattern| pattern.match?(relative_path) }
      end

      def read_file(path)
        File.binread(path, MAX_FILE_BYTES)
      rescue StandardError => e
        "[unreadable: #{e.class.name}]"
      end
    end

    class OperationalSetupSection < Base
      def sections(context)
        [
          section(
            "operational_setup",
            OperationalSetup.new(project: context.project).discover(workspace_path: context.workspace_path),
            "project_operational_setup"
          )
        ]
      end
    end

    class Protocols < Base
      def sections(context)
        selector = ProtocolDocumentSelector.new(
          protocol_state: context.project.protocol_state,
          context_policy: context.request["context_policy"] || "implementation_default"
        )
        selected_documents = selector.selected_documents

        [
          protocol_section("protocol_files", protocol_file_payload(selected_documents), selector.selection_metadata),
          protocol_section("protocol_model", protocol_model_payload(context.project.protocol_state, selected_documents), selector.selection_metadata)
        ]
      end

      private

      def protocol_file_payload(documents)
        documents.filter_map do |document|
          path = document.fetch("path", nil)
          next if path.blank?

          {
            "key" => document.fetch("key", nil),
            "path" => path,
            "title" => document.fetch("title", path),
            "layer" => document.fetch("layer", nil),
            "position" => document.fetch("position", nil),
            "provenance" => document.fetch("provenance", {}),
            "content" => document.fetch("body", "").to_s,
            "truncated" => false
          }
        end
      end

      def protocol_model_payload(protocol_state, selected_documents)
        protocol_state.merge(
          "documents" => selected_documents,
          "selection_source" => "project_protocol_model"
        )
      end

      def protocol_section(name, content, selection_metadata)
        section = section(name, content, "project_protocol_model")
        section.metadata.merge!(
          "context_layer" => "protocols",
          "selection_source" => "project_protocol_model",
          "selected_protocol_documents" => selection_metadata
        )
        section
      end
    end

    class ProtocolDocumentSelector
      DEFAULT_KEYS_BY_POLICY = {
        "implementation_default" => %w[agents_root conventions linting architecture playbooks],
        "modification_default" => %w[agents_root conventions linting architecture playbooks],
        "diagnosis_default" => %w[agents_root conventions linting architecture playbooks],
        "evaluation_default" => %w[agents_root conventions linting architecture playbooks],
        "operation_default" => %w[agents_root playbooks],
        "planning_default" => %w[agents_root architecture playbooks],
        "documentation_default" => %w[agents_root conventions architecture documentation playbooks],
        "exploration_default" => %w[agents_root architecture playbooks]
      }.freeze

      def initialize(protocol_state:, context_policy:)
        @protocol_state = protocol_state || {}
        @context_policy = context_policy.to_s
      end

      def selected_documents
        @selected_documents ||= documents.select { |document| selected_document?(document) }.sort_by { |document| [document.fetch("position", 0).to_i, document.fetch("id", 0).to_i] }
      end

      def selection_metadata
        selected_documents.map do |document|
          {
            "key" => document.fetch("key", nil),
            "path" => document.fetch("path", nil),
            "title" => document.fetch("title", nil),
            "layer" => document.fetch("layer", nil),
            "position" => document.fetch("position", nil),
            "provenance" => document.fetch("provenance", {}),
            "selection_reason" => selection_reason(document)
          }
        end
      end

      private

      attr_reader :protocol_state, :context_policy

      def documents
        Array(protocol_state.fetch("documents", []))
      end

      def selected_document?(document)
        return true if context_policy == Redwright::LLM::ContextPolicy::FULL_CONTEXT_FALLBACK

        selected_keys.include?(document.fetch("key", "").to_s) ||
          selected_layers.include?(document.fetch("layer", "").to_s) ||
          selected_path?(document.fetch("path", "").to_s)
      end

      def selected_keys
        DEFAULT_KEYS_BY_POLICY.fetch(context_policy, [])
      end

      def selected_layers
        return %w[behavioral stack] if context_policy.end_with?("_default")

        []
      end

      def selected_path?(path)
        path == "AGENTS.md" || path.start_with?(".agents/")
      end

      def selection_reason(document)
        key = document.fetch("key", "").to_s
        return "matched_key:#{key}" if selected_keys.include?(key)

        layer = document.fetch("layer", "").to_s
        return "matched_layer:#{layer}" if selected_layers.include?(layer)

        "matched_path:#{document.fetch("path", "")}"
      end
    end

    class PreviousInteractions < Base
      def initialize(store:, limit:)
        @store = store
        @limit = limit
      end

      def sections(context)
        [
          section(
            "previous_interactions",
            {
              "scope" => "agent_llm_loop",
              "human_chat_included" => false,
              "records" => previous_interaction_records(context.ticket, context.request)
            },
            "historical_agent_llm_interaction"
          )
        ]
      end

      private

      attr_reader :store, :limit

      def previous_interaction_records(ticket, request)
        return [] unless store

        store.recent(ticket: ticket, request: request, limit: limit)
      end
    end

    class ValidationFeedback < Base
      def sections(context)
        return [] unless context.request["validation_feedback"].present?

        [
          section(
            "validation_feedback",
            context.request.fetch("validation_feedback"),
            "current_execution_feedback"
          )
        ]
      end
    end
  end
end
