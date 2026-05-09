require Rails.root.join("..", "..", "lib", "redwright", "llm", "context_policy").expand_path.to_s
require Rails.root.join("..", "..", "lib", "redwright", "tree_sitter_structural_extractor").expand_path.to_s

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
    DOCUMENT_OPS_FILE_PATTERNS = [
      %r{\Aops/specs/specs/[^/]+\.md\z},
      %r{\Aops/plans/[^/]+\.md\z},
      %r{\Aops/trackers/[^/]+\.md\z}
    ].freeze
    QUIZ_INCLUDED_POLICIES = %w[
      planning_default
      documentation_default
      exploration_default
      full_context_fallback
    ].freeze
    DUMP_INCLUDED_POLICIES = %w[
      planning_default
      documentation_default
      exploration_default
      full_context_fallback
    ].freeze
    CONVERSATION_INCLUDED_POLICIES = Redwright::LLM::ContextPolicy::POLICY_REGISTRY.values.select do |policy|
      policy.included_layers.include?("conversation")
    end.map(&:name).freeze
    TREE_SITTER_SUPPORTED_EXTENSIONS = Redwright::TreeSitterStructuralExtractor::SUPPORTED_EXTENSIONS.keys.freeze

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
        ticket = section("ticket", ticket_payload(context.ticket, context.request), "ticket_record")
        project = section("project", project_payload(context.project), "project_record")
        ticket.metadata["context_layer"] = "prompt"
        project.metadata["context_layer"] = "project"

        [ticket, project]
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
        repository_tree = section("repository_tree", repository_tree_payload(files), "workspace_filesystem")
        relevant_files = section("relevant_files", file_payload(context.workspace_path, relevant_files(files)), "workspace_filesystem")
        tests = section("tests", file_payload(context.workspace_path, test_files(files)), "workspace_filesystem")
        repository_tree.metadata["context_layer"] = "file_tree"
        relevant_files.metadata["context_layer"] = "concrete_files"
        tests.metadata["context_layer"] = "concrete_files"

        [repository_tree, relevant_files, tests]
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
        section = section(
          "operational_setup",
          OperationalSetup.new(project: context.project).discover(workspace_path: context.workspace_path),
          "project_operational_setup"
        )
        section.metadata["context_layer"] = "agent"

        [section]
      end
    end

    class TreeSitterContext < Base
      MAX_FILES = 24
      MAX_SYMBOLS_PER_FILE = 32

      def sections(context)
        inventory = TreeSitterContextInventory.new(context: context)
        files = inventory.files
        symbols = extract_symbols(context.workspace_path, files)
        section = section(
          "tree_sitter",
          {
            "parser_mode" => "preferred_tree_sitter",
            "supported_extensions" => TREE_SITTER_SUPPORTED_EXTENSIONS,
            "files" => files,
            "symbols" => symbols
          },
          "workspace_semantic_parser"
        )
        section.metadata.merge!(
          "context_layer" => "tree_sitter",
          "selection_source" => "tree_sitter_context_inventory",
          "parser_mode" => "preferred_tree_sitter",
          "supported_extensions" => TREE_SITTER_SUPPORTED_EXTENSIONS,
          "selected_files" => files,
          "symbols_count" => symbols.length
        )
        [section]
      end

      private

      def extract_symbols(workspace_path, files)
        extractor = Redwright::TreeSitterStructuralExtractor.new
        files.flat_map do |file|
          extractor.extract(
            project_path: workspace_path,
            rel_path: file.fetch("path"),
            max_symbols: MAX_SYMBOLS_PER_FILE
          )
        end.sort_by { |symbol| [symbol.fetch(:path).to_s, symbol.fetch(:line).to_i, symbol.fetch(:kind).to_s, symbol.fetch(:name).to_s] }
      end
    end

    class TreeSitterContextInventory
      def initialize(context:)
        @context = context
      end

      def files
        root = context.workspace_path.to_s
        return [] unless File.directory?(root)

        Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).filter_map do |path|
          next unless File.file?(path)

          relative = path.delete_prefix("#{root}/")
          next if skipped_path?(relative)
          next unless TREE_SITTER_SUPPORTED_EXTENSIONS.include?(File.extname(relative))

          {"path" => relative, "language" => language_for(relative), "bytes" => File.size(path)}
        end.sort_by { |file| file.fetch("path") }.first(TreeSitterContext::MAX_FILES)
      end

      private

      attr_reader :context

      def skipped_path?(relative_path)
        relative_path.split(File::SEPARATOR).any? { |part| SKIPPED_DIRECTORIES.include?(part) } ||
          PROTOCOL_FILE_PATTERNS.any? { |pattern| pattern.match?(relative_path) }
      end

      def language_for(path)
        Redwright::TreeSitterStructuralExtractor::SUPPORTED_EXTENSIONS.fetch(File.extname(path)).to_s
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
      DEFAULT_LAYERS_BY_POLICY = {
        "implementation_default" => %w[behavioral stack],
        "modification_default" => %w[behavioral stack],
        "diagnosis_default" => %w[behavioral stack],
        "evaluation_default" => %w[behavioral stack],
        "operation_default" => %w[behavioral],
        "planning_default" => %w[behavioral],
        "documentation_default" => %w[behavioral],
        "exploration_default" => %w[behavioral]
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
        DEFAULT_LAYERS_BY_POLICY.fetch(context_policy, [])
      end

      def selected_path?(path)
        path == "AGENTS.md"
      end

      def selection_reason(document)
        key = document.fetch("key", "").to_s
        return "matched_key:#{key}" if selected_keys.include?(key)

        layer = document.fetch("layer", "").to_s
        return "matched_layer:#{layer}" if selected_layers.include?(layer)

        "matched_path:#{document.fetch("path", "")}"
      end
    end

    class Documents < Base
      MAX_DOCUMENTS = 12
      MAX_DOCUMENT_BYTES = 16_000
      ARTIFACT_TYPES_BY_POLICY = {
        "implementation_default" => %w[spec plan_tracker],
        "modification_default" => %w[spec plan_tracker],
        "diagnosis_default" => %w[spec plan_tracker],
        "evaluation_default" => %w[spec plan_tracker],
        "operation_default" => %w[plan_tracker],
        "planning_default" => Document::TYPES,
        "documentation_default" => Document::TYPES,
        "exploration_default" => Document::TYPES
      }.freeze

      def sections(context)
        inventory = DocumentContextInventory.new(context: context)
        selector = DocumentContextSelector.new(
          documents: inventory.documents,
          ticket: context.ticket,
          context_policy: context.request["context_policy"] || "implementation_default"
        )

        [document_section(selector)]
      end

      private

      def document_section(selector)
        selected_documents = selector.selected_documents
        omitted_documents = selector.omitted_documents
        section = section(
          "documents",
          {
            "sources" => selector.sources,
            "documents" => selected_documents.map { |document| payload(document) },
            "omitted_documents" => omitted_documents.map { |document| omitted_payload(document) }
          },
          "project_documents"
        )
        section.metadata.merge!(
          "context_layer" => "docs",
          "selection_source" => "document_context_inventory",
          "selected_documents" => selected_documents.map { |document| trace_payload(document) },
          "omitted_documents" => omitted_documents.map { |document| trace_payload(document) }
        )
        section
      end

      def payload(document)
        trace_payload(document).merge(
          "body" => truncate(document.fetch("body", "").to_s),
          "truncated" => document.fetch("body", "").to_s.bytesize > MAX_DOCUMENT_BYTES
        )
      end

      def omitted_payload(document)
        trace_payload(document)
      end

      def trace_payload(document)
        {
          "source" => document.fetch("source"),
          "id" => document["id"],
          "project_id" => document["project_id"],
          "use_case_id" => document["use_case_id"],
          "artifact_type" => document.fetch("artifact_type"),
          "title" => document.fetch("title"),
          "path" => document["path"],
          "selection_reason" => document.fetch("selection_reason", nil),
          "omission_reason" => document.fetch("omission_reason", nil)
        }.compact
      end

      def truncate(value)
        value.bytesize > MAX_DOCUMENT_BYTES ? value.byteslice(0, MAX_DOCUMENT_BYTES) : value
      end
    end

    class DocumentContextInventory
      def initialize(context:)
        @context = context
      end

      def documents
        persisted_documents + repository_ops_documents
      end

      private

      attr_reader :context

      def persisted_documents
        context.project.documents.order(updated_at: :desc, created_at: :desc).limit(Documents::MAX_DOCUMENTS * 2).map do |document|
          {
            "source" => "persisted_document",
            "id" => document.id,
            "project_id" => document.project_id,
            "use_case_id" => document.use_case_id,
            "artifact_type" => document.artifact_type,
            "title" => document.title,
            "body" => document.body.to_s,
            "updated_at" => document.updated_at
          }
        end
      end

      def repository_ops_documents
        root = repository_root
        return [] unless root && File.directory?(root)

        Dir.glob(File.join(root, "ops", "**", "*.md")).filter_map do |path|
          relative = path.delete_prefix("#{root}/")
          next unless DOCUMENT_OPS_FILE_PATTERNS.any? { |pattern| pattern.match?(relative) }

          {
            "source" => "repository_ops_artifact",
            "artifact_type" => artifact_type_for_path(relative),
            "title" => File.basename(path, ".md"),
            "path" => relative,
            "body" => read_file(path),
            "updated_at" => File.mtime(path)
          }
        end.sort_by { |document| document.fetch("path") }.first(Documents::MAX_DOCUMENTS)
      end

      def repository_root
        root = Rails.root.join("..", "..").expand_path.to_s
        return root if File.directory?(File.join(root, "ops"))

        workspace = context.workspace_path.to_s
        return workspace if File.directory?(File.join(workspace, "ops"))

        nil
      end

      def artifact_type_for_path(relative_path)
        case relative_path
        when %r{\Aops/specs/}
          "spec"
        when %r{\Aops/plans/}, %r{\Aops/trackers/}
          "plan_tracker"
        else
          "draft"
        end
      end

      def read_file(path)
        File.binread(path, Documents::MAX_DOCUMENT_BYTES)
      rescue StandardError => e
        "[unreadable: #{e.class.name}]"
      end
    end

    class DocumentContextSelector
      attr_reader :documents, :ticket, :context_policy

      def initialize(documents:, ticket:, context_policy:)
        @documents = documents
        @ticket = ticket
        @context_policy = context_policy.to_s
      end

      def selected_documents
        @selected_documents ||= documents.filter_map do |document|
          next unless selected_document?(document)

          document.merge("selection_reason" => selection_reason(document))
        end.first(Documents::MAX_DOCUMENTS)
      end

      def omitted_documents
        @omitted_documents ||= documents.filter_map do |document|
          next if selected_document?(document)

          document.merge("omission_reason" => omission_reason(document))
        end
      end

      def sources
        documents.map { |document| document.fetch("source") }.uniq.sort
      end

      private

      def selected_document?(document)
        return true if context_policy == Redwright::LLM::ContextPolicy::FULL_CONTEXT_FALLBACK
        return false unless matched_use_case_scope?(document)

        selected_artifact_types.include?(document.fetch("artifact_type").to_s)
      end

      def matched_use_case_scope?(document)
        use_case_id = document["use_case_id"]
        return true if use_case_id.blank?

        ticket.use_case_id.present? && use_case_id == ticket.use_case_id
      end

      def selected_artifact_types
        Documents::ARTIFACT_TYPES_BY_POLICY.fetch(context_policy, Document::TYPES)
      end

      def selection_reason(document)
        return "matched_use_case:#{document.fetch("use_case_id")}:#{document.fetch("artifact_type")}" if document["use_case_id"].present?

        "matched_artifact_type:#{document.fetch("artifact_type")}"
      end

      def omission_reason(document)
        return "unmatched_use_case:#{document.fetch("use_case_id")}" unless matched_use_case_scope?(document)

        "unselected_artifact_type:#{document.fetch("artifact_type")}"
      end
    end

    class Quizzes < Base
      MAX_QUIZZES = 6
      MAX_ENTRIES = 12

      def sections(context)
        inventory = QuizContextInventory.new(context: context)
        selector = QuizContextSelector.new(
          quizzes: inventory.quizzes,
          entries: inventory.entries,
          ticket: context.ticket,
          context_policy: context.request["context_policy"] || "implementation_default"
        )

        [quiz_section(selector)]
      end

      private

      def quiz_section(selector)
        selected_quizzes = selector.selected_quizzes
        selected_entries = selector.selected_entries
        omitted_quizzes = selector.omitted_quizzes
        omitted_entries = selector.omitted_entries
        section = section(
          "quizzes",
          {
            "quizzes" => selected_quizzes.map { |quiz| quiz_payload(quiz) },
            "entries" => selected_entries.map { |entry| entry_payload(entry) },
            "omitted_quizzes" => omitted_quizzes.map { |quiz| quiz_trace_payload(quiz) },
            "omitted_entries" => omitted_entries.map { |entry| entry_trace_payload(entry) }
          },
          "project_quiz_model"
        )
        section.metadata.merge!(
          "context_layer" => "quizzes",
          "selection_source" => "quiz_context_inventory",
          "selected_quizzes" => selected_quizzes.map { |quiz| quiz_trace_payload(quiz) },
          "selected_entries" => selected_entries.map { |entry| entry_trace_payload(entry) },
          "omitted_quizzes" => omitted_quizzes.map { |quiz| quiz_trace_payload(quiz) },
          "omitted_entries" => omitted_entries.map { |entry| entry_trace_payload(entry) }
        )
        section
      end

      def quiz_payload(quiz)
        quiz_trace_payload(quiz).merge(
          "current_question" => quiz["current_question"],
          "current_tags" => quiz.fetch("current_tags", []),
          "current_prompt_intent" => quiz.fetch("current_prompt_intent", {}),
          "candidate_questions" => quiz.fetch("candidate_questions", [])
        )
      end

      def entry_payload(entry)
        entry_trace_payload(entry).merge(
          "question" => entry.fetch("question"),
          "answer" => entry.fetch("answer"),
          "tags" => entry.fetch("tags", [])
        )
      end

      def quiz_trace_payload(quiz)
        {
          "id" => quiz.fetch("id"),
          "project_id" => quiz.fetch("project_id"),
          "use_case_id" => quiz["use_case_id"],
          "name" => quiz.fetch("name"),
          "status" => quiz.fetch("status"),
          "mode" => quiz.fetch("mode"),
          "selection_reason" => quiz["selection_reason"],
          "omission_reason" => quiz["omission_reason"]
        }.compact
      end

      def entry_trace_payload(entry)
        {
          "id" => entry.fetch("id"),
          "quiz_id" => entry.fetch("quiz_id"),
          "project_id" => entry.fetch("project_id"),
          "use_case_id" => entry["use_case_id"],
          "status" => entry.fetch("status"),
          "selection_reason" => entry["selection_reason"],
          "omission_reason" => entry["omission_reason"]
        }.compact
      end
    end

    class QuizContextInventory
      def initialize(context:)
        @context = context
      end

      def quizzes
        context.project.quizzes.order(updated_at: :desc, created_at: :desc).limit(Quizzes::MAX_QUIZZES * 2).map do |quiz|
          {
            "id" => quiz.id,
            "project_id" => quiz.project_id,
            "use_case_id" => quiz.use_case_id,
            "name" => quiz.name,
            "status" => quiz.status,
            "mode" => quiz.mode,
            "current_question" => quiz.current_question,
            "current_tags" => quiz.current_tags,
            "current_prompt_intent" => quiz.current_prompt_intent,
            "candidate_questions" => quiz.candidate_questions
          }
        end
      end

      def entries
        context.project.quiz_entries.includes(:tags).order(created_at: :desc, id: :desc).limit(Quizzes::MAX_ENTRIES * 2).map do |entry|
          {
            "id" => entry.id,
            "quiz_id" => entry.quiz_id,
            "project_id" => entry.project_id,
            "use_case_id" => entry.use_case_id,
            "status" => entry.status,
            "question" => entry.question,
            "answer" => entry.answer,
            "tags" => entry.tags.map(&:name).sort
          }
        end
      end

      private

      attr_reader :context
    end

    class QuizContextSelector
      attr_reader :quizzes, :entries, :ticket, :context_policy

      def initialize(quizzes:, entries:, ticket:, context_policy:)
        @quizzes = quizzes
        @entries = entries
        @ticket = ticket
        @context_policy = context_policy.to_s
      end

      def selected_quizzes
        @selected_quizzes ||= quizzes.filter_map do |quiz|
          next unless selected_quiz?(quiz)

          quiz.merge("selection_reason" => selection_reason(quiz))
        end.first(Quizzes::MAX_QUIZZES)
      end

      def omitted_quizzes
        @omitted_quizzes ||= quizzes.filter_map do |quiz|
          next if selected_quiz?(quiz)

          quiz.merge("omission_reason" => omission_reason(quiz))
        end
      end

      def selected_entries
        @selected_entries ||= entries.filter_map do |entry|
          next unless selected_entry?(entry)

          entry.merge("selection_reason" => selection_reason(entry))
        end.first(Quizzes::MAX_ENTRIES)
      end

      def omitted_entries
        @omitted_entries ||= entries.filter_map do |entry|
          next if selected_entry?(entry)

          entry.merge("omission_reason" => omission_reason(entry))
        end
      end

      private

      def selected_quiz?(quiz)
        return false unless context_policy_allows_quizzes?
        return false unless matched_use_case_scope?(quiz)

        quiz.fetch("status") == "active"
      end

      def selected_entry?(entry)
        return false unless context_policy_allows_quizzes?
        return false unless matched_use_case_scope?(entry)

        entry.fetch("status") == "answered"
      end

      def context_policy_allows_quizzes?
        QUIZ_INCLUDED_POLICIES.include?(context_policy)
      end

      def matched_use_case_scope?(record)
        use_case_id = record["use_case_id"]
        return true if use_case_id.blank?

        ticket.use_case_id.present? && use_case_id == ticket.use_case_id
      end

      def selection_reason(record)
        return "matched_use_case:#{record.fetch("use_case_id")}:#{context_policy}" if record["use_case_id"].present?

        "matched_project:#{context_policy}"
      end

      def omission_reason(record)
        return "policy_excludes_quizzes:#{context_policy}" unless context_policy_allows_quizzes?
        return "unmatched_use_case:#{record.fetch("use_case_id")}" unless matched_use_case_scope?(record)

        "unselected_status:#{record.fetch("status")}"
      end
    end

    class Dumps < Base
      MAX_DUMPS = 8
      MAX_DUMP_BYTES = 20_000

      def sections(context)
        inventory = DumpContextInventory.new(context: context)
        selector = DumpContextSelector.new(
          dumps: inventory.dumps,
          ticket: context.ticket,
          project: context.project,
          context_policy: context.request["context_policy"] || "implementation_default"
        )

        [dump_section(selector)]
      end

      private

      def dump_section(selector)
        selected_dumps = selector.selected_dumps
        omitted_dumps = selector.omitted_dumps
        section = section(
          "dumps",
          {
            "dumps" => selected_dumps.map { |dump| payload(dump) },
            "omitted_dumps" => omitted_dumps.map { |dump| trace_payload(dump) }
          },
          "repository_dump_artifacts"
        )
        section.metadata.merge!(
          "context_layer" => "dumps",
          "selection_source" => "dump_context_inventory",
          "selected_dumps" => selected_dumps.map { |dump| trace_payload(dump) },
          "omitted_dumps" => omitted_dumps.map { |dump| trace_payload(dump) }
        )
        section
      end

      def payload(dump)
        trace_payload(dump).merge(
          "body" => truncate(dump.fetch("body", "").to_s),
          "truncated" => dump.fetch("body", "").to_s.bytesize > MAX_DUMP_BYTES
        )
      end

      def trace_payload(dump)
        {
          "source" => dump.fetch("source"),
          "title" => dump.fetch("title"),
          "topic" => dump.fetch("topic"),
          "path" => dump.fetch("path"),
          "selection_reason" => dump["selection_reason"],
          "omission_reason" => dump["omission_reason"]
        }.compact
      end

      def truncate(value)
        value.bytesize > MAX_DUMP_BYTES ? value.byteslice(0, MAX_DUMP_BYTES) : value
      end
    end

    class DumpContextInventory
      def initialize(context:)
        @context = context
      end

      def dumps
        root = repository_root
        return [] unless root

        Dir.glob(File.join(root, "ops", "conv", "dump", "*-dump.md")).filter_map do |path|
          relative = path.delete_prefix("#{root}/")
          next if relative.end_with?("-dump-raw.md")

          {
            "source" => "repository_dump_artifact",
            "title" => title_for(path),
            "topic" => topic_for(path),
            "path" => relative,
            "body" => read_file(path),
            "updated_at" => File.mtime(path)
          }
        end.sort_by { |dump| dump.fetch("path") }.first(Dumps::MAX_DUMPS * 2)
      end

      private

      attr_reader :context

      def repository_root
        workspace = context.workspace_path.to_s
        return workspace if File.directory?(File.join(workspace, "ops", "conv", "dump"))

        root = Rails.root.join("..", "..").expand_path.to_s
        return root if File.directory?(File.join(root, "ops", "conv", "dump"))

        nil
      end

      def title_for(path)
        first_heading = File.foreach(path).find { |line| line.start_with?("# ") }
        first_heading ? first_heading.delete_prefix("# ").strip : File.basename(path, ".md")
      rescue StandardError
        File.basename(path, ".md")
      end

      def topic_for(path)
        File.basename(path, "-dump.md").sub(/\A\d{4}-\d{2}-\d{2}-/, "")
      end

      def read_file(path)
        File.binread(path, Dumps::MAX_DUMP_BYTES)
      rescue StandardError => e
        "[unreadable: #{e.class.name}]"
      end
    end

    class DumpContextSelector
      attr_reader :dumps, :ticket, :project, :context_policy

      def initialize(dumps:, ticket:, project:, context_policy:)
        @dumps = dumps
        @ticket = ticket
        @project = project
        @context_policy = context_policy.to_s
      end

      def selected_dumps
        @selected_dumps ||= dumps.filter_map do |dump|
          next unless selected_dump?(dump)

          dump.merge("selection_reason" => selection_reason(dump))
        end.first(Dumps::MAX_DUMPS)
      end

      def omitted_dumps
        @omitted_dumps ||= dumps.filter_map do |dump|
          next if selected_dump?(dump)

          dump.merge("omission_reason" => omission_reason(dump))
        end
      end

      private

      def selected_dump?(dump)
        return false unless context_policy_allows_dumps?

        relevant_to_ticket?(dump) || relevant_to_project?(dump)
      end

      def context_policy_allows_dumps?
        DUMP_INCLUDED_POLICIES.include?(context_policy)
      end

      def relevant_to_ticket?(dump)
        ticket_terms.any? { |term| dump_terms(dump).include?(term) }
      end

      def relevant_to_project?(dump)
        project_terms.any? { |term| dump_terms(dump).include?(term) }
      end

      def ticket_terms
        @ticket_terms ||= tokenize(
          [
            ticket.title,
            ticket.description,
            ticket.scope,
            ticket.kind,
            ticket.use_case&.name
          ].compact.join(" ")
        )
      end

      def project_terms
        @project_terms ||= tokenize([project.name, project.description, project.stack_slug].compact.join(" "))
      end

      def dump_terms(dump)
        tokenize([dump.fetch("topic"), dump.fetch("title"), dump.fetch("path")].join(" "))
      end

      def tokenize(value)
        value.to_s.downcase.scan(/[a-z0-9][a-z0-9-]{2,}/).uniq
      end

      def selection_reason(dump)
        matching_ticket_term = ticket_terms.find { |term| dump_terms(dump).include?(term) }
        return "matched_ticket_topic:#{matching_ticket_term}" if matching_ticket_term

        matching_project_term = project_terms.find { |term| dump_terms(dump).include?(term) }
        "matched_project_topic:#{matching_project_term}"
      end

      def omission_reason(dump)
        return "policy_excludes_dumps:#{context_policy}" unless context_policy_allows_dumps?

        "no_topic_match"
      end
    end

    class DerivedLlmContext < Base
      def initialize(store:, limit:)
        @store = store
        @limit = limit
      end

      def sections(context)
        selector = DerivedLlmContextSelector.new(
          store: store,
          limit: limit,
          ticket: context.ticket,
          request: context.request
        )
        summaries = selector.prior_attempt_summaries
        section = section(
          "llm_based_context",
          {
            "source_inventory" => selector.source_inventory,
            "prior_attempt_summaries" => summaries
          },
          "llm_derived_summary"
        )
        section.metadata.merge!(
          "context_layer" => "llm_based",
          "selection_source" => "previous_interaction_store",
          "authority" => "derived_from_agent_llm_interactions",
          "freshness_source" => "previous_interaction_created_at",
          "freshness" => selector.freshness_metadata(summaries),
          "selected_sources" => summaries.map { |summary| source_trace(summary) }
        )
        [section]
      end

      private

      attr_reader :store, :limit

      def source_trace(summary)
        {
          "source" => summary.fetch("source"),
          "created_at" => summary.fetch("created_at"),
          "outcome" => summary.fetch("outcome", nil)
        }.compact
      end
    end

    class DerivedLlmContextSelector
      def initialize(store:, limit:, ticket:, request:)
        @store = store
        @limit = limit
        @ticket = ticket
        @request = request
      end

      def prior_attempt_summaries
        @prior_attempt_summaries ||= previous_records.map do |record|
          {
            "source" => "agent_llm_previous_interaction",
            "created_at" => record.fetch("created_at", nil),
            "project_id" => record.fetch("project_id", nil),
            "ticket_id" => record.fetch("ticket_id", nil),
            "session_id" => record.fetch("session_id", nil),
            "outcome" => record.fetch("outcome", nil),
            "failure_summary" => record.fetch("failure_summary", nil),
            "response_status" => record.dig("response_payload", "status"),
            "response_summary" => record.dig("response_payload", "summary"),
            "context_section_names" => Array(record.fetch("context_section_names", [])),
            "derived_summary" => derived_summary(record)
          }.compact
        end
      end

      def source_inventory
        {
          "agent_llm_previous_interactions" => {
            "status" => store ? "operational" : "not_configured",
            "scope" => "ticket_session_jsonl",
            "records" => previous_records.length
          },
          "provider_generated_summaries" => {
            "status" => "not_used",
            "scope" => "future_explicit_summary_generation"
          }
        }
      end

      def freshness_metadata(summaries)
        timestamps = summaries.filter_map { |summary| summary["created_at"] }
        {
          "latest_created_at" => timestamps.max,
          "records" => summaries.length,
          "stale" => timestamps.empty?
        }
      end

      private

      attr_reader :store, :limit, :ticket, :request

      def previous_records
        @previous_records ||= store ? store.recent(ticket: ticket, request: request, limit: limit) : []
      end

      def derived_summary(record)
        [
          "outcome=#{record.fetch("outcome", "unknown")}",
          ("failure=#{record["failure_summary"]}" if record["failure_summary"].present?),
          ("response=#{record.dig("response_payload", "summary")}" if record.dig("response_payload", "summary").present?)
        ].compact.join("; ")
      end
    end

    class PreviousInteractions < Base
      def initialize(store:, limit:)
        @store = store
        @limit = limit
      end

      def sections(context)
        agent_records = previous_interaction_records(context.ticket, context.request)
        conversation_selector = ConversationContextSelector.new(
          context: context,
          limit: limit,
          context_policy: context.request["context_policy"] || "implementation_default",
          agent_interaction_store_configured: store.present?
        )
        selected_comments = conversation_selector.selected_comments
        omitted_comments = conversation_selector.omitted_comments
        section = section(
          "previous_interactions",
          {
            "scope" => "agent_ticket_execution_conversation",
            "human_chat_included" => selected_comments.any? { |comment| comment.fetch("author_type") == "user" },
            "records" => agent_records,
            "agent_llm_records" => agent_records,
            "ticket_comments" => selected_comments.map { |comment| comment_payload(comment) },
            "omitted_ticket_comments" => omitted_comments.map { |comment| comment_trace_payload(comment) },
            "selection_policy" => conversation_selector.selection_policy,
            "storage_inventory" => conversation_selector.storage_inventory
          },
          "historical_conversation"
        )
        section.metadata.merge!(
          "context_layer" => "conversation",
          "selection_source" => "conversation_context_inventory",
          "agent_llm_records" => agent_records.length,
          "selection_policy" => conversation_selector.selection_policy,
          "selected_ticket_comments" => selected_comments.map { |comment| comment_trace_payload(comment) },
          "omitted_ticket_comments" => omitted_comments.map { |comment| comment_trace_payload(comment) },
          "storage_inventory" => conversation_selector.storage_inventory
        )

        [section]
      end

      private

      attr_reader :store, :limit

      def previous_interaction_records(ticket, request)
        return [] unless store

        store.recent(ticket: ticket, request: request, limit: limit)
      end

      def comment_payload(comment)
        comment_trace_payload(comment).merge(
          "body" => comment.fetch("body"),
          "mentions" => comment.fetch("mentions")
        )
      end

      def comment_trace_payload(comment)
        {
          "id" => comment.fetch("id"),
          "ticket_id" => comment.fetch("ticket_id"),
          "use_case_id" => comment["use_case_id"],
          "author_type" => comment.fetch("author_type"),
          "author_label" => comment.fetch("author_label"),
          "author_handle" => comment["author_handle"],
          "created_at" => comment.fetch("created_at"),
          "selection_reason" => comment["selection_reason"],
          "omission_reason" => comment["omission_reason"]
        }.compact
      end
    end

    class ConversationContextSelector
      attr_reader :context, :limit, :context_policy, :agent_interaction_store_configured

      def initialize(context:, limit:, context_policy:, agent_interaction_store_configured:)
        @context = context
        @limit = limit
        @context_policy = context_policy.to_s
        @agent_interaction_store_configured = agent_interaction_store_configured
      end

      def selected_comments
        @selected_comments ||= comment_records.filter_map do |comment|
          next unless selected_comment?(comment)

          comment.merge("selection_reason" => selection_reason(comment))
        end.first(limit)
      end

      def omitted_comments
        @omitted_comments ||= comment_records.filter_map do |comment|
          next if selected_comment?(comment)

          comment.merge("omission_reason" => omission_reason(comment))
        end
      end

      def storage_inventory
        {
          "ticket_comments" => {
            "status" => "operational",
            "scope" => "project_ticket_comments",
            "records" => comment_records.length
          },
          "telegram_chat_context" => {
            "status" => "context_pointer_only",
            "scope" => "chat_to_project_workstream_mapping"
          },
          "tui_runtime_messages" => {
            "status" => "transient_queue",
            "scope" => "in_memory_turn_events"
          },
          "agent_llm_interactions" => {
            "status" => agent_interaction_store_configured ? "operational" : "not_configured",
            "scope" => "ticket_session_jsonl"
          }
        }
      end

      def selection_policy
        {
          "context_policy" => context_policy,
          "project_id" => context.project.id,
          "ticket_id" => context.ticket.id,
          "use_case_id" => context.ticket.use_case_id,
          "included_when" => "same_ticket_or_same_use_case_or_relevant_project_topic"
        }
      end

      private

      def comment_records
        @comment_records ||= TicketComment
          .joins(ticket: :board)
          .where(boards: {project_id: context.project.id})
          .includes(:mentions, :ticket)
          .order(created_at: :desc, id: :desc)
          .limit(limit * 4)
          .map { |comment| record_for(comment) }
      end

      def selected_comment?(comment)
        return false unless context_policy_allows_conversation?

        same_ticket?(comment) || same_use_case?(comment) || relevant_project_topic?(comment)
      end

      def context_policy_allows_conversation?
        CONVERSATION_INCLUDED_POLICIES.include?(context_policy)
      end

      def same_ticket?(comment)
        comment.fetch("ticket_id") == context.ticket.id
      end

      def same_use_case?(comment)
        context.ticket.use_case_id.present? && comment["use_case_id"] == context.ticket.use_case_id
      end

      def relevant_project_topic?(comment)
        project_terms.any? { |term| tokenize(comment.fetch("body")).include?(term) }
      end

      def selection_reason(comment)
        return "matched_ticket:#{comment.fetch("ticket_id")}" if same_ticket?(comment)
        return "matched_use_case:#{comment.fetch("use_case_id")}" if same_use_case?(comment)

        term = project_terms.find { |candidate| tokenize(comment.fetch("body")).include?(candidate) }
        "matched_project_topic:#{term}"
      end

      def omission_reason(_comment)
        return "policy_excludes_conversation:#{context_policy}" unless context_policy_allows_conversation?

        "no_conversation_scope_match"
      end

      def project_terms
        @project_terms ||= tokenize([context.project.name, context.project.description, context.ticket.title, context.ticket.description].compact.join(" "))
      end

      def tokenize(value)
        value.to_s.downcase.scan(/[a-z0-9][a-z0-9-]{2,}/).uniq
      end

      def record_for(comment)
        {
          "id" => comment.id,
          "ticket_id" => comment.ticket_id,
          "use_case_id" => comment.ticket.use_case_id,
          "author_type" => comment.author_type,
          "author_label" => comment.author_label,
          "author_handle" => comment.author_handle,
          "body" => comment.body,
          "mentions" => comment.mentions.map do |mention|
            {
              "handle" => mention.handle,
              "target_type" => mention.target_type,
              "target_id" => mention.target_id,
              "display_label" => mention.display_label
            }.compact
          end,
          "created_at" => comment.created_at&.iso8601
        }
      end

    end

    class ValidationFeedback < Base
      def sections(context)
        return [] unless context.request["validation_feedback"].present?

        section = section(
          "validation_feedback",
          context.request.fetch("validation_feedback"),
          "current_execution_feedback"
        )
        section.metadata["context_layer"] = "prompt"

        [section]
      end
    end
  end
end
