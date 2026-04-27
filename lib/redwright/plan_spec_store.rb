# frozen_string_literal: true

require "fileutils"

module Redwright
  PlanSpecArtifacts = Struct.new(:functional_spec_path, :technical_spec_path, keyword_init: true)

  class PlanSpecStore
    def initialize(base_dir: Dir.pwd)
      @base_dir = base_dir
    end

    def generate(project:, workstream:, turns:)
      drafts_dir = File.join(@base_dir, "ops", "specs", "drafts")
      FileUtils.mkdir_p(drafts_dir)

      stamp = Time.now.utc.strftime("%Y-%m-%d")
      base_name = "#{stamp}-#{project.name}-#{workstream.id}"

      functional_path = File.join(drafts_dir, "#{base_name}-functional-spec.md")
      technical_path = File.join(drafts_dir, "#{base_name}-technical-spec.md")

      write_functional_spec(functional_path, project: project, workstream: workstream, turns: turns)
      write_technical_spec(technical_path, project: project, workstream: workstream, turns: turns)

      PlanSpecArtifacts.new(functional_spec_path: functional_path, technical_spec_path: technical_path)
    end

    private

    def write_functional_spec(path, project:, workstream:, turns:)
      content = <<~MD
        # Functional Specification

        - project: #{project.name}
        - project_id: #{project.id}
        - workstream_id: #{workstream.id}
        - intent: #{workstream.intent}

        ## Alignment Inputs
      MD

      turns.each_with_index do |t, idx|
        content << "\n### Q#{idx + 1}\n"
        content << "- question: #{t[:question]}\n"
        content << "- answer: #{t[:answer]}\n"
      end

      File.write(path, content)
    end

    def write_technical_spec(path, project:, workstream:, turns:)
      content = <<~MD
        # Technical Specification

        - project: #{project.name}
        - project_id: #{project.id}
        - workstream_id: #{workstream.id}

        ## Derived Implementation Notes

        - Alignment was completed through #{turns.size} question/answer turns.
        - Workstream state reached `ready`.
        - Runtime must preserve one-question-at-a-time progression for `plan`.
      MD

      File.write(path, content)
    end
  end
end
