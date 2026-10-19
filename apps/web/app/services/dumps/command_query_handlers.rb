module Dumps
  class CommandQueryHandlers
    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def register(dispatcher)
      {"OpenDump" => :open_dump, "UpdateDump" => :update_dump, "CurateDump" => :curate_dump}.each do |name, action|
        dispatcher.register_command(name, handler(action))
      end
      {"ListDumps" => :list_dumps, "ShowDump" => :show_dump}.each do |name, action|
        dispatcher.register_query(name, handler(action))
      end
    end

    private

    def handler(action)
      lambda do |payload:, context:, request_id:|
        values = payload.stringify_keys
        project = Project.find(values.fetch("project_id"))
        Dump.reconcile!(project)
        data = public_send(action, project, values)
        CommandQuery::Result.ok(request_id: request_id, data: data)
      rescue ActiveRecord::RecordNotFound => error
        CommandQuery::Result.error(request_id: request_id, code: "dump_not_found", message: error.message)
      rescue KeyError, ActiveRecord::RecordInvalid => error
        CommandQuery::Result.error(request_id: request_id, code: "dump_invalid_payload", message: error.message)
      rescue Specifications::Error => error
        CommandQuery::Result.error(request_id: request_id, code: error.code.to_s, message: error.message)
      end
    end

    public

    def open_dump(project, values)
      dump = Documents.new(project).open(use_case_name: values["use_case_name"], title: values["title"])
      {"status" => "opened", "dump" => dump_data(dump), "summary" => "Dump opened."}
    end

    def update_dump(project, values)
      dump = project.dumps.find(values.fetch("dump_id"))
      Documents.new(project).update(dump, body: values.fetch("body"), revision: values.fetch("revision"), status: values.fetch("status", dump.status))
      {"status" => "updated", "dump" => dump_data(dump), "summary" => "Dump saved."}
    end

    def curate_dump(project, values)
      dump = project.dumps.find(values.fetch("dump_id"))
      Documents.new(project).curate(dump, revision: values.fetch("revision"))
      {"status" => "updated", "dump" => dump_data(dump), "summary" => "Dump curated."}
    end

    def list_dumps(project, values)
      limit = [[values.fetch("limit", 20).to_i, 1].max, 100].min
      dumps = project.dumps.includes(:use_case).order(source_modified_at: :desc, id: :desc).limit(limit)
      {"status" => "listed", "dumps" => dumps.map { |dump| dump_data(dump) }, "summary" => "Dumps listed."}
    end

    def show_dump(project, values)
      identifier = values.fetch("identifier").to_s
      dump = project.dumps.find_by(slug: identifier)
      dump ||= project.dumps.find_by(id: identifier) if identifier.match?(/\A[0-9]+\z/)
      raise ActiveRecord::RecordNotFound, "Dump not found." unless dump
      {"status" => "shown", "dump" => dump_data(dump), "summary" => "Dump loaded."}
    end

    private

    def dump_data(dump)
      entry = dump.source
      dump.attributes.slice("id", "project_id", "use_case_id", "title", "slug", "status", "relative_path").merge(
        "use_case_name" => dump.use_case&.name, "revision" => entry[:source_hash], "body" => entry[:body]
      )
    end
  end
end
