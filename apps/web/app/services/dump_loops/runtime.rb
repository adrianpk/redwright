module DumpLoops
  class Runtime
    Result = Struct.new(
      :ok,
      :status,
      :dump,
      :entry,
      :dumps,
      :fallback_reason,
      :errors,
      keyword_init: true
    ) do
      def ok?
        ok == true
      end
    end

    def initialize(project:, use_case_name: nil, dump: nil, title: nil, curation_provider: CurationProvider.new)
      @project = project
      @use_case_name = use_case_name
      @dump = dump
      @title = title
      @curation_provider = curation_provider
    end

    def open
      resolved = resolve_dump!
      Result.new(ok: true, status: resolved.capture_status, dump: resolved, entry: nil, dumps: [], fallback_reason: "", errors: [])
    end

    def append!(raw_input:)
      resolved = resolve_dump!
      return closed_result(resolved) unless resolved.capturing?

      polished = curation_provider.polish_entry(input: entry_input_for(resolved, raw_input))
      entry = resolved.entries.create!(
        raw_input: raw_input.to_s,
        polished_input: polished.attributes.fetch("polished_input"),
        derived_thread_hint: polished.attributes.fetch("derived_thread_hints").first.to_s
      )
      refresh_raw_body!(resolved)
      Result.new(
        ok: true,
        status: "capturing",
        dump: resolved.reload,
        entry: entry,
        dumps: [],
        fallback_reason: polished.fallback_reason,
        errors: polished.errors
      )
    end

    def done!
      resolved = resolve_dump!
      resolved.update!(status: "completed", capture_status: "closed")
      curated = apply_curation!(resolved)
      Result.new(
        ok: true,
        status: "done",
        dump: resolved.reload,
        entry: nil,
        dumps: [],
        fallback_reason: curated.fallback_reason,
        errors: curated.errors
      )
    end

    def cancel!
      resolved = resolve_dump!
      resolved.update!(status: "cancelled", capture_status: "closed")
      Result.new(ok: true, status: "cancelled", dump: resolved, entry: nil, dumps: [], fallback_reason: "", errors: [])
    end

    def list(limit: 20)
      Result.new(ok: true, status: "listed", dump: nil, entry: nil, dumps: dumps_scope.limit(limit), fallback_reason: "", errors: [])
    end

    def show(identifier)
      resolved = dumps_scope.find_by(id: identifier) || dumps_scope.find_by(slug: identifier.to_s)
      return Result.new(ok: false, status: "not_found", dump: nil, entry: nil, dumps: [], fallback_reason: "", errors: ["dump not found"]) unless resolved

      Result.new(ok: true, status: "shown", dump: resolved, entry: nil, dumps: [], fallback_reason: "", errors: [])
    end

    def curate!
      resolved = resolve_dump!
      curated = apply_curation!(resolved)
      Result.new(
        ok: true,
        status: "curated",
        dump: resolved.reload,
        entry: nil,
        dumps: [],
        fallback_reason: curated.fallback_reason,
        errors: curated.errors
      )
    end

    private

    attr_reader :project, :use_case_name, :dump, :title, :curation_provider

    def resolve_dump!
      return @dump if @dump

      active = dumps_scope.where(status: "active", capture_status: "capturing").order(updated_at: :desc).first
      return @dump = active if active && title.to_s.strip.empty?

      @dump = project.dumps.create!(use_case: use_case, title: title.presence || default_title)
    end

    def dumps_scope
      scope = project.dumps.order(updated_at: :desc, created_at: :desc)
      return scope.project_level if use_case.nil?

      scope.for_use_case(use_case.id)
    end

    def use_case
      @use_case ||= resolve_use_case
    end

    def resolve_use_case
      return nil if use_case_name.to_s.strip.empty?

      project.use_cases.find_or_create_by!(slug: use_case_slug) do |record|
        record.name = use_case_name.to_s.strip
        record.description = "Use case created from dump scope."
      end
    end

    def use_case_slug
      use_case_name.to_s.strip.parameterize
    end

    def default_title
      base = use_case ? "#{use_case.name} Dump" : "#{project.name} Dump"
      "#{base} #{Time.current.strftime('%Y-%m-%d %H:%M')}"
    end

    def closed_result(resolved)
      Result.new(ok: false, status: "closed", dump: resolved, entry: nil, dumps: [], fallback_reason: "", errors: ["dump capture is closed"])
    end

    def entry_input_for(resolved, raw_input)
      {
        "project" => project_payload,
        "dump" => dump_payload(resolved),
        "raw_input" => raw_input.to_s,
        "entries" => entries_payload(resolved)
      }
    end

    def curation_input_for(resolved)
      {
        "project" => project_payload,
        "dump" => dump_payload(resolved),
        "raw_body" => resolved.raw_body,
        "entries" => entries_payload(resolved)
      }
    end

    def project_payload
      {
        "id" => project.id,
        "name" => project.name,
        "description" => project.description,
        "stack_slug" => project.stack_slug
      }
    end

    def dump_payload(resolved)
      {
        "id" => resolved.id,
        "title" => resolved.title,
        "use_case_id" => resolved.use_case_id,
        "status" => resolved.status,
        "capture_status" => resolved.capture_status,
        "curation_status" => resolved.curation_status
      }
    end

    def entries_payload(resolved)
      resolved.entries.ordered.map do |entry|
        {
          "position" => entry.position,
          "raw_input" => entry.raw_input,
          "polished_input" => entry.polished_input,
          "derived_thread_hint" => entry.derived_thread_hint
        }
      end
    end

    def refresh_raw_body!(resolved)
      resolved.update!(raw_body: resolved.entries.ordered.map(&:polished_input).join("\n\n"))
    end

    def apply_curation!(resolved)
      refresh_raw_body!(resolved)
      resolved.update!(curation_status: "curating")
      curated = curation_provider.curate_dump(input: curation_input_for(resolved.reload))
      attributes = curated.attributes
      resolved.update!(
        curation_status: curated.usable? ? "curated" : "needs_review",
        curated_body: curated_body_from(attributes),
        summary: attributes.fetch("summary")
      )
      curated
    end

    def curated_body_from(attributes)
      [
        "# #{attributes.fetch("central_topic")}",
        "",
        "## Summary",
        attributes.fetch("summary"),
        "",
        section("Key Concepts", attributes.fetch("key_concepts")),
        section("Decisions Or Preferences", attributes.fetch("decisions_or_preferences")),
        section("Tensions And Tradeoffs", attributes.fetch("tensions_and_tradeoffs")),
        section("Assumptions", attributes.fetch("assumptions")),
        section("Derived Threads", attributes.fetch("derived_threads")),
        section("Possible Downstream Artifacts", attributes.fetch("possible_downstream_artifacts")),
        section("Open Questions", attributes.fetch("open_questions"))
      ].flatten.join("\n").strip
    end

    def section(title, values)
      return [] if values.empty?

      ["", "## #{title}", values.map { |value| "- #{value}" }]
    end
  end
end
