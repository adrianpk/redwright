module DumpLoops
  class CommandQueryHandlers
    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def register(dispatcher)
      dispatcher.register_command("OpenDump", method(:open_dump))
      dispatcher.register_command("AppendDump", method(:append_dump))
      dispatcher.register_command("DoneDump", method(:done_dump))
      dispatcher.register_command("CancelDump", method(:cancel_dump))
      dispatcher.register_command("CurateDump", method(:curate_dump))
      dispatcher.register_query("ListDumps", method(:list_dumps))
      dispatcher.register_query("ShowDump", method(:show_dump))
    end

    private

    def open_dump(payload:, context:, request_id:)
      project = Project.find(payload_value(payload, "project_id"))
      runtime = Runtime.new(project: project, use_case_name: payload_value(payload, "use_case_name"), title: payload_value(payload, "title"))
      result = runtime.open

      CommandQuery::Result.ok(request_id: request_id, data: data_from(result))
    rescue ActiveRecord::RecordNotFound => e
      CommandQuery::Result.error(request_id: request_id, code: "dump_project_not_found", message: e.message)
    end

    def append_dump(payload:, context:, request_id:)
      project = Project.find(payload_value(payload, "project_id"))
      dump = Dump.find(payload_value(payload, "dump_id"))
      result = Runtime.new(project: project, dump: dump).append!(raw_input: payload_value(payload, "raw_input"))

      CommandQuery::Result.ok(request_id: request_id, data: data_from(result))
    rescue ActiveRecord::RecordNotFound => e
      CommandQuery::Result.error(request_id: request_id, code: "dump_not_found", message: e.message)
    rescue KeyError => e
      CommandQuery::Result.error(request_id: request_id, code: "dump_invalid_payload", message: e.message)
    end

    def done_dump(payload:, context:, request_id:)
      project = Project.find(payload_value(payload, "project_id"))
      dump = Dump.find(payload_value(payload, "dump_id"))
      result = Runtime.new(project: project, dump: dump).done!

      CommandQuery::Result.ok(request_id: request_id, data: data_from(result))
    rescue ActiveRecord::RecordNotFound => e
      CommandQuery::Result.error(request_id: request_id, code: "dump_not_found", message: e.message)
    end

    def cancel_dump(payload:, context:, request_id:)
      project = Project.find(payload_value(payload, "project_id"))
      dump = Dump.find(payload_value(payload, "dump_id"))
      result = Runtime.new(project: project, dump: dump).cancel!

      CommandQuery::Result.ok(request_id: request_id, data: data_from(result))
    rescue ActiveRecord::RecordNotFound => e
      CommandQuery::Result.error(request_id: request_id, code: "dump_not_found", message: e.message)
    end

    def curate_dump(payload:, context:, request_id:)
      project = Project.find(payload_value(payload, "project_id"))
      dump = Dump.find(payload_value(payload, "dump_id"))
      result = Runtime.new(project: project, dump: dump).curate!

      CommandQuery::Result.ok(request_id: request_id, data: data_from(result))
    rescue ActiveRecord::RecordNotFound => e
      CommandQuery::Result.error(request_id: request_id, code: "dump_not_found", message: e.message)
    end

    def list_dumps(payload:, context:, request_id:)
      project = Project.find(payload_value(payload, "project_id"))
      limit = (payload_value(payload, "limit") || 20).to_i
      dumps = project.dumps.includes(:use_case).order(updated_at: :desc, created_at: :desc).limit(limit)

      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "status" => "listed",
          "dump" => nil,
          "entry" => nil,
          "dumps" => dumps.map { |dump| dump_data(dump) },
          "fallback_reason" => "",
          "errors" => [],
          "summary" => "Dumps listed."
        }
      )
    rescue ActiveRecord::RecordNotFound => e
      CommandQuery::Result.error(request_id: request_id, code: "dump_project_not_found", message: e.message)
    end

    def show_dump(payload:, context:, request_id:)
      project = Project.find(payload_value(payload, "project_id"))
      identifier = payload_value(payload, "identifier")
      dump = project.dumps.find_by(id: identifier) || project.dumps.find_by(slug: identifier.to_s)
      return CommandQuery::Result.error(request_id: request_id, code: "dump_not_found", message: "dump not found") unless dump

      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "status" => "shown",
          "dump" => dump_data(dump),
          "entry" => nil,
          "dumps" => [],
          "fallback_reason" => "",
          "errors" => [],
          "summary" => "Dump loaded."
        }
      )
    rescue ActiveRecord::RecordNotFound => e
      CommandQuery::Result.error(request_id: request_id, code: "dump_project_not_found", message: e.message)
    rescue KeyError => e
      CommandQuery::Result.error(request_id: request_id, code: "dump_invalid_payload", message: e.message)
    end

    def payload_value(payload, key)
      payload.fetch(key) { payload.fetch(key.to_sym, nil) }
    end

    def data_from(result)
      {
        "status" => result.status,
        "dump" => dump_data(result.dump),
        "entry" => entry_data(result.entry),
        "dumps" => result.dumps.map { |dump| dump_data(dump) },
        "fallback_reason" => result.fallback_reason,
        "errors" => result.errors,
        "summary" => summary_for(result)
      }
    end

    def dump_data(dump)
      return nil unless dump

      {
        "id" => dump.id,
        "project_id" => dump.project_id,
        "use_case_id" => dump.use_case_id,
        "use_case_name" => dump.use_case&.name,
        "title" => dump.title,
        "slug" => dump.slug,
        "status" => dump.status,
        "capture_status" => dump.capture_status,
        "curation_status" => dump.curation_status,
        "entry_count" => dump.entries.count,
        "summary" => dump.summary,
        "raw_body" => dump.raw_body,
        "curated_body" => dump.curated_body
      }
    end

    def entry_data(entry)
      return nil unless entry

      {
        "id" => entry.id,
        "position" => entry.position,
        "polished_input" => entry.polished_input,
        "derived_thread_hint" => entry.derived_thread_hint
      }
    end

    def summary_for(result)
      case result.status
      when "capturing"
        result.entry ? "Dump entry captured." : "Dump capture open."
      when "done"
        "Dump capture completed and curated."
      when "cancelled"
        "Dump capture cancelled."
      when "listed"
        "Dumps listed."
      when "shown"
        "Dump loaded."
      when "curated"
        "Dump curated."
      else
        "Dump updated."
      end
    end
  end
end
