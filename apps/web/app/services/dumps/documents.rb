module Dumps
  class Documents
    def initialize(project)
      @project = project
    end

    def open(use_case_name: nil, title: nil)
      Dump.reconcile!(@project)
      use_case = if use_case_name.present?
        @project.use_cases.find_or_create_by!(name: use_case_name.strip) do |record|
          record.description = "Use case created for a dump document."
        end
      end
      @project.dumps.find_by(use_case: use_case) || @project.dumps.create!(use_case: use_case, title: title)
    end

    def curate(dump, revision:, harness: Harness.new)
      ensure_project!(dump)
      entry = dump.source
      raise Specifications::Error.new("The file changed. Reload it before curating.", code: :conflict) unless revision == entry[:source_hash]
      raise Specifications::Error, "Write some dump content before curating." if entry[:body].blank?
      context = {"project" => @project.attributes.slice("name", "description"),
        "use_case" => dump.use_case&.attributes&.slice("name", "description"),
        "dump" => {"title" => entry[:title], "body" => entry[:body]}}
      output = harness.generate(context: context, workspace: FileStore.new(@project).root.to_s)
      update(dump, body: output.fetch("body"), revision: revision)
    end

    def update(dump, body:, revision:, status: dump.status)
      raise Specifications::Error.new("Reload the document before saving.", code: :conflict) if revision.blank?
      ensure_project!(dump)
      raise Specifications::Error, "Dump body must be Markdown text." unless body.is_a?(String)
      dump.revision = revision
      dump.update!(body: body, status: status)
      dump
    end

    private

    def ensure_project!(dump)
      raise Specifications::Error, "Dump belongs to another project." if dump.project_id != @project.id
    end
  end
end
