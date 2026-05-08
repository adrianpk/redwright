require "json"

require Rails.root.join("..", "..", "lib", "redwright", "llm", "context_section").expand_path.to_s

module AgentTicketExecution
  class ContextComposer
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

    Context = Struct.new(:context_sections, :trace_metadata, :user_text, :diagnostics, keyword_init: true) do
      def llm_request_inputs
        {
          context_sections: context_sections,
          trace_metadata: trace_metadata,
          user_text: user_text
        }
      end
    end

    def compose(ticket:, request:, workspace:)
      project = ticket.project
      workspace_path = workspace&.workspace_path || project.root_path
      files = repository_files(workspace_path)
      sections = [
        section("ticket", ticket_payload(ticket, request), "ticket_record"),
        section("project", project_payload(project), "project_record"),
        section("repository_tree", repository_tree_payload(files), "workspace_filesystem"),
        section("relevant_files", file_payload(workspace_path, relevant_files(files)), "workspace_filesystem"),
        section("tests", file_payload(workspace_path, test_files(files)), "workspace_filesystem"),
        section("operational_setup", operational_setup_payload(project, workspace_path), "project_operational_setup"),
        section("protocol_files", protocol_file_payload(project, workspace_path), "workspace_filesystem"),
        section("protocol_model", project.protocol_state, "project_protocol_model")
      ]

      Context.new(
        context_sections: sections,
        trace_metadata: trace_metadata(ticket, project, workspace_path, sections),
        user_text: JSON.generate(user_text_payload(ticket, request)),
        diagnostics: diagnostics(sections)
      )
    end

    private

    def section(name, content, authority)
      Redwright::LLM::ContextSection.new(
        name: name,
        content: content,
        authority: authority,
        metadata: section_metadata(content)
      )
    end

    def ticket_payload(ticket, request)
      {
        "id" => ticket.id,
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

    def repository_tree_payload(files)
      {
        "entries" => files.first(MAX_TREE_ENTRIES).map do |file|
          {"path" => file.fetch(:path), "type" => "file", "bytes" => file.fetch(:bytes)}
        end,
        "truncated" => files.length > MAX_TREE_ENTRIES,
        "total_files" => files.length
      }
    end

    def operational_setup_payload(project, workspace_path)
      OperationalSetup.new(project: project).discover(workspace_path: workspace_path)
    end

    def protocol_file_payload(project, workspace_path)
      project.protocol_state.fetch("documents", []).filter_map do |document|
        path = document.fetch("path", nil)
        next if path.blank?

        full_path = File.expand_path(path, workspace_path)
        next unless safe_child_path?(workspace_path, full_path)
        next unless File.file?(full_path)

        {
          "path" => path,
          "title" => document.fetch("title", path),
          "content" => read_file(full_path),
          "truncated" => File.size(full_path) > MAX_FILE_BYTES
        }
      end
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

        {path: relative, bytes: File.size(path)}
      end.sort_by { |file| file.fetch(:path) }
    end

    def skipped_path?(relative_path)
      relative_path.split(File::SEPARATOR).any? { |part| SKIPPED_DIRECTORIES.include?(part) }
    end

    def read_file(path)
      File.binread(path, MAX_FILE_BYTES)
    rescue StandardError => e
      "[unreadable: #{e.class.name}]"
    end

    def safe_child_path?(root, path)
      expanded_root = File.expand_path(root)
      expanded_path = File.expand_path(path)
      expanded_path == expanded_root || expanded_path.start_with?("#{expanded_root}/")
    end

    def trace_metadata(ticket, project, workspace_path, sections)
      {
        trace_id: nil,
        project_id: project.id,
        project_ref: project.repo_url,
        project_root: workspace_path,
        ticket_id: ticket.id,
        context_summary: sections.map(&:to_h),
        context_bytes: sections.sum(&:bytes),
        context_sections: sections.map(&:name)
      }
    end

    def user_text_payload(ticket, request)
      {
        "action" => "agent_ticket_execution",
        "ticket_id" => ticket.id,
        "ticket_title" => ticket.title,
        "ticket_description" => ticket.description,
        "mode" => request.fetch("mode"),
        "branch_name" => request["branch_name"]
      }
    end

    def diagnostics(sections)
      {
        "section_names" => sections.map(&:name),
        "section_authorities" => sections.to_h { |section| [section.name, section.authority] },
        "context_bytes" => sections.sum(&:bytes)
      }
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
end
