require "fileutils"
require "json"

module AgentTicketExecution
  class OperationalSetup
    ROOT_DIRECTORY = "rw".freeze
    AGENT_DIRECTORY = "agent".freeze
    DOCKERFILE_NAME = "Dockerfile".freeze
    METADATA_NAME = "runtime-setup.json".freeze
    README_NAME = "README.md".freeze

    def initialize(project:)
      @project = project
    end

    def ensure!(workspace_path: project.root_path)
      setup = discover(workspace_path: workspace_path)
      return setup if setup.fetch("available")

      dockerfile = generated_dockerfile
      return setup.merge("status" => "missing_generated_setup") unless dockerfile

      FileUtils.mkdir_p(agent_directory_path(workspace_path))
      File.write(dockerfile_path(workspace_path), dockerfile.fetch("content"))
      File.write(metadata_path(workspace_path), JSON.pretty_generate(metadata_payload(dockerfile)))
      File.write(readme_path(workspace_path), readme_body)

      discover(workspace_path: workspace_path).merge(
        "status" => "materialized",
        "source" => "runtime_container_generated_file",
        "runtime_container_id" => project.runtime_container&.id
      )
    end

    def discover(workspace_path: project.root_path)
      root_path = File.expand_path(workspace_path.to_s)
      agent_path = agent_directory_path(root_path)
      dockerfile = dockerfile_path(root_path)
      metadata = metadata_path(root_path)

      {
        "available" => File.file?(dockerfile),
        "status" => File.file?(dockerfile) ? "available" : "missing",
        "source" => metadata_source(metadata),
        "root_path" => File.join(root_path, ROOT_DIRECTORY),
        "agent_path" => agent_path,
        "dockerfile_path" => dockerfile,
        "metadata_path" => metadata,
        "root_relative_path" => ROOT_DIRECTORY,
        "agent_relative_path" => File.join(ROOT_DIRECTORY, AGENT_DIRECTORY),
        "dockerfile_relative_path" => File.join(ROOT_DIRECTORY, AGENT_DIRECTORY, DOCKERFILE_NAME),
        "metadata_relative_path" => File.join(ROOT_DIRECTORY, AGENT_DIRECTORY, METADATA_NAME),
        "production_dockerfile_path" => production_dockerfile_path(root_path),
        "production_dockerfile_separate" => production_dockerfile_separate?(root_path),
        "runtime_container_id" => project.runtime_container&.id
      }
    end

    private

    attr_reader :project

    def generated_dockerfile
      project.runtime_container&.generated_files&.find do |file|
        file.fetch("path", "") == DOCKERFILE_NAME && file.fetch("content", "").present?
      end
    end

    def metadata_payload(dockerfile)
      {
        "schema_version" => 1,
        "purpose" => "agent_ticket_execution",
        "source" => "runtime_container_generated_file",
        "runtime_container_id" => project.runtime_container&.id,
        "dockerfile_source_path" => dockerfile.fetch("path"),
        "notes" => [
          "This Dockerfile is for RedWright agent work only.",
          "It is not the production Dockerfile for this project."
        ]
      }
    end

    def metadata_source(metadata)
      return "project_file" unless File.file?(metadata)

      JSON.parse(File.read(metadata)).fetch("source", "project_file")
    rescue JSON::ParserError
      "project_file"
    end

    def readme_body
      <<~MARKDOWN
        # RedWright Agent Runtime Setup

        This directory contains operational setup files for agent ticket execution.

        The Dockerfile in this directory is a working environment for RedWright agents. It is not the production Dockerfile for the project.
      MARKDOWN
    end

    def agent_directory_path(root_path)
      File.join(root_path, ROOT_DIRECTORY, AGENT_DIRECTORY)
    end

    def dockerfile_path(root_path)
      File.join(agent_directory_path(root_path), DOCKERFILE_NAME)
    end

    def metadata_path(root_path)
      File.join(agent_directory_path(root_path), METADATA_NAME)
    end

    def readme_path(root_path)
      File.join(agent_directory_path(root_path), README_NAME)
    end

    def production_dockerfile_path(root_path)
      path = File.join(root_path, DOCKERFILE_NAME)
      File.file?(path) ? path : nil
    end

    def production_dockerfile_separate?(root_path)
      production_dockerfile_path(root_path).nil? || production_dockerfile_path(root_path) != dockerfile_path(root_path)
    end
  end
end
