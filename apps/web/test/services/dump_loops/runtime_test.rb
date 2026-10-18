require "test_helper"

module DumpLoops
  class RuntimeTest < ActiveSupport::TestCase
    test "opens a project dump" do
      project = create_project(key: "dump-runtime-open")

      result = Runtime.new(project: project, title: "Architecture Dump", curation_provider: StaticCurationProvider.new).open

      assert result.ok?
      assert_equal "capturing", result.status
      assert_equal project.id, result.dump.project_id
      assert_nil result.dump.use_case_id
      assert_equal "Architecture Dump", result.dump.title
    end

    test "opens a use case dump and creates use case when missing" do
      project = create_project(key: "dump-runtime-use-case")

      result = Runtime.new(project: project, use_case_name: "Billing Flow", curation_provider: StaticCurationProvider.new).open

      use_case = project.use_cases.find_by!(slug: "billing-flow")
      assert result.ok?
      assert_equal use_case.id, result.dump.use_case_id
      assert_equal "Billing Flow", result.dump.title
      assert_equal "Use case created from dump scope.", use_case.description
    end

    test "reopens existing active dump for same scope" do
      project = create_project(key: "dump-runtime-reopen")
      runtime = Runtime.new(project: project, title: "Project Dump", curation_provider: StaticCurationProvider.new)

      first = runtime.open
      second = Runtime.new(project: project, curation_provider: StaticCurationProvider.new).open

      assert_equal first.dump, second.dump
      assert_equal 1, project.dumps.count
    end

    test "appends entry and refreshes polished raw body" do
      project = create_project(key: "dump-runtime-append")
      provider = StaticCurationProvider.new
      runtime = Runtime.new(project: project, title: "Project Dump", curation_provider: provider)

      result = runtime.append!(raw_input: "teh first note")

      assert result.ok?
      assert_equal "capturing", result.status
      assert_equal "The first note.", result.entry.polished_input
      assert_equal "derived-thread", result.entry.derived_thread_hint
      assert_equal "The first note.", result.dump.raw_body
      assert_equal "teh first note", provider.polish_inputs.first.fetch("raw_input")
    end

    test "appends multiple entries into one dump" do
      project = create_project(key: "dump-runtime-multiple")
      runtime = Runtime.new(project: project, title: "Project Dump", curation_provider: StaticCurationProvider.new)

      runtime.append!(raw_input: "first")
      result = runtime.append!(raw_input: "second")

      assert_equal 2, result.dump.entries.count
      assert_equal "The first note.\n\nThe first note.", result.dump.raw_body
    end

    test "done closes capture and writes curated output" do
      project = create_project(key: "dump-runtime-done")
      provider = StaticCurationProvider.new
      runtime = Runtime.new(project: project, title: "Project Dump", curation_provider: provider)
      runtime.append!(raw_input: "first")

      result = runtime.done!

      assert result.ok?
      assert_equal "done", result.status
      assert_equal "completed", result.dump.status
      assert_equal "closed", result.dump.capture_status
      assert_equal "curated", result.dump.curation_status
      assert_equal "Curated summary.", result.dump.summary
      assert_includes result.dump.curated_body, "# Curated Dump"
      assert_equal "Project Dump", provider.curate_inputs.first.fetch("dump").fetch("title")
    end

    test "cancel closes capture without deleting entries" do
      project = create_project(key: "dump-runtime-cancel")
      runtime = Runtime.new(project: project, title: "Project Dump", curation_provider: StaticCurationProvider.new)
      runtime.append!(raw_input: "first")

      result = runtime.cancel!

      assert result.ok?
      assert_equal "cancelled", result.status
      assert_equal "cancelled", result.dump.status
      assert_equal "closed", result.dump.capture_status
      assert_equal 1, result.dump.entries.count
    end

    test "does not append to closed dump" do
      project = create_project(key: "dump-runtime-closed")
      dump = project.dumps.create!(title: "Closed", status: "completed", capture_status: "closed")

      result = Runtime.new(project: project, dump: dump, curation_provider: StaticCurationProvider.new).append!(raw_input: "late")

      assert_not result.ok?
      assert_equal "closed", result.status
      assert_equal 0, dump.entries.count
      assert_includes result.errors, "dump capture is closed"
    end

    test "lists scoped dumps in recent order" do
      project = create_project(key: "dump-runtime-list")
      use_case = create_use_case(project: project, name: "Billing")
      project_dump = project.dumps.create!(title: "Project Dump")
      use_case_dump = project.dumps.create!(use_case: use_case, title: "Billing Dump")

      project_results = Runtime.new(project: project, curation_provider: StaticCurationProvider.new).list.dumps
      use_case_results = Runtime.new(project: project, use_case_name: "Billing", curation_provider: StaticCurationProvider.new).list.dumps

      assert_equal [project_dump.id], project_results.map(&:id)
      assert_equal [use_case_dump.id], use_case_results.map(&:id)
    end

    test "shows dump by slug within scope" do
      project = create_project(key: "dump-runtime-show")
      dump = project.dumps.create!(title: "Project Dump")

      result = Runtime.new(project: project, curation_provider: StaticCurationProvider.new).show("project-dump")

      assert result.ok?
      assert_equal dump, result.dump
    end

    test "curate can refresh curation without closing capture" do
      project = create_project(key: "dump-runtime-curate")
      runtime = Runtime.new(project: project, title: "Project Dump", curation_provider: StaticCurationProvider.new)
      runtime.append!(raw_input: "first")

      result = runtime.curate!

      assert result.ok?
      assert_equal "curated", result.status
      assert_equal "active", result.dump.status
      assert_equal "capturing", result.dump.capture_status
      assert_equal "curated", result.dump.curation_status
    end

    test "marks curation as needs review when provider falls back" do
      project = create_project(key: "dump-runtime-needs-review")
      runtime = Runtime.new(project: project, title: "Project Dump", curation_provider: FallbackCurationProvider.new)
      runtime.append!(raw_input: "first")

      result = runtime.done!

      assert_not_empty result.errors
      assert_equal "llm_malformed", result.fallback_reason
      assert_equal "needs_review", result.dump.curation_status
      assert_equal "Fallback summary.", result.dump.summary
    end

    class StaticCurationProvider
      attr_reader :polish_inputs, :curate_inputs

      def initialize
        @polish_inputs = []
        @curate_inputs = []
      end

      def polish_entry(input:)
        polish_inputs << input
        CurationProvider::Result.new(
          usable: true,
          attributes: {
            "polished_input" => "The first note.",
            "topic_heading" => "Context",
            "derived_thread_hints" => ["derived-thread"],
            "tag_suggestions" => ["context"],
            "warnings" => []
          },
          fallback_reason: "",
          errors: []
        )
      end

      def curate_dump(input:)
        curate_inputs << input
        CurationProvider::Result.new(
          usable: true,
          attributes: {
            "central_topic" => "Curated Dump",
            "summary" => "Curated summary.",
            "key_concepts" => ["Dump"],
            "decisions_or_preferences" => ["Use repeated posts."],
            "tensions_and_tradeoffs" => [],
            "assumptions" => [],
            "derived_threads" => ["derived-thread"],
            "possible_downstream_artifacts" => [],
            "open_questions" => [],
            "tag_suggestions" => ["dump"]
          },
          fallback_reason: "",
          errors: []
        )
      end
    end

    class FallbackCurationProvider < StaticCurationProvider
      def curate_dump(input:)
        curate_inputs << input
        CurationProvider::Result.new(
          usable: false,
          attributes: {
            "central_topic" => "Fallback Dump",
            "summary" => "Fallback summary.",
            "key_concepts" => [],
            "decisions_or_preferences" => [],
            "tensions_and_tradeoffs" => [],
            "assumptions" => [],
            "derived_threads" => [],
            "possible_downstream_artifacts" => [],
            "open_questions" => [],
            "tag_suggestions" => []
          },
          fallback_reason: "llm_malformed",
          errors: ["invalid curation"]
        )
      end
    end
  end
end
