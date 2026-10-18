require "test_helper"

class FeatureWorkflowTest < ActiveSupport::TestCase
  setup do
    @specification = create_document(status: "approved", body: "# Manual contract\n\nKeep the existing behavior.")
    @feature = @specification.use_case
    @project = @feature.project
    @board = create_board(project: @project)
    @ready = @board.columns.create!(key: "backlog", title: "Ready", position: 0)
    @working = @board.columns.create!(key: "in_progress", title: "Working", position: 1)
    @tracker = Specifications::Tracker.new(project: @project)
  end

  test "regeneration incorporates later discovery into the same spec and invalidates its slicing" do
    # The user can author first and add discovery later without creating a second contract.
    ticket = @board.tickets.create!(column: @ready, title: "Existing work", use_case: @feature)
    @tracker.generate!(specification: @specification, tickets: [ticket])
    dump = @project.dumps.create!(use_case: @feature, title: "Later context")
    dump.entries.create!(raw_input: "Consolidate invoices")
    quiz = @feature.find_or_create_quiz!
    quiz.entries.create!(question: "Currency?", answer: "USD", status: "answered")
    program = harness_program(<<~'RUBY')
      raise "missing original" unless context.fetch("current_specification").fetch("body").include?("Manual contract")
      raise "missing dump" unless context.fetch("dumps").first.fetch("entries").first.fetch("raw_input") == "Consolidate invoices"
      raise "missing answer" unless context.fetch("quiz_answers").first.fetch("answer") == "USD"
      {title: "Revised contract", body: "# Revised\n\nConsolidated USD invoices."}
    RUBY
    old_id, old_path = @specification.id, @specification.relative_path
    assert_no_difference "Document.count" do
      result = Specifications::Generator.new(project: @project, use_case: @feature,
        harness: Specifications::Harness.new(program: program)).call
      assert_equal old_id, result.id
      assert_equal old_path, result.relative_path
      assert_equal "draft", result.status
      assert_includes result.body, "Consolidated USD invoices"
    end
    assert_equal "needs_review", Features::Workflow.new(@feature).tracker_entry[:status]
    assert_nil AgentTicketExecution::TicketSelectionPolicy.new.pick(board: @board).ticket
    assert_equal @feature.id, ticket.reload.use_case_id
  end

  test "slicing retains useful ticket identities and closes omitted work without orphaning it" do
    kept = @board.tickets.create!(column: @ready, title: "Keep", use_case: @feature)
    obsolete = @board.tickets.create!(column: @ready, title: "Remove", use_case: @feature)
    original = @tracker.generate!(specification: @specification, tickets: [kept, obsolete])
    program = harness_program(<<~'RUBY')
      key = context.fetch("existing_tickets").find { |ticket| ticket["title"] == "Keep" }.fetch("key")
      {tickets: [{key: key, title: "Keep refined", body: "Retained acceptance criteria"}, {key: nil, title: "New slice", body: "Additional acceptance criteria"}]}
    RUBY
    result = Specifications::Slicing.new(specification: @specification,
      harness: Specifications::Slicing::Harness.new(program: program)).call
    assert_equal original[:path], result[:path]
    assert_equal kept.ticket_key, result[:metadata]["ticket_keys"].first
    assert_equal "Keep refined", kept.reload.title
    assert_equal "closed", obsolete.reload.workflow_status
    assert_equal "obsolete", obsolete.resolution
    assert_equal @feature.id, obsolete.use_case_id
    assert_equal @specification.relative_path, obsolete.specification_path
    assert_equal original[:path], obsolete.tracker_path
    assert_raises(ActiveRecord::RecordNotDestroyed) { obsolete.destroy! }
    assert_equal 2, @tracker.pending_tickets.size
  end

  test "execution permanently blocks revision even after moving a ticket back to ready" do
    ticket = @board.tickets.create!(column: @ready, title: "Begin delivery", use_case: @feature)
    @tracker.generate!(specification: @specification, tickets: [ticket])
    ticket.transition_to_column!(@working)
    ticket.transition_to_column!(@ready)
    assert ticket.started_at
    workflow = Features::Workflow.new(@feature)
    assert workflow.started?
    original = @specification.source
    assert_raises(Specifications::Error) { @specification.revise!(attributes: {body: "Changed contract", status: "draft"}, revision: original[:source_hash]) }
    assert_raises(Specifications::Error) { @tracker.generate!(specification: @specification, tickets: [ticket]) }
    assert_raises(Specifications::Error) { Specifications::Generator.new(project: @project, use_case: @feature, harness: Specifications::Harness.new(program: "/bin/false")).call }
    assert_equal original[:source_hash], @specification.source[:source_hash]
    path = Pathname.new(@project.root_path).join(@specification.relative_path)
    path.write(path.read + "\nExternal contract change\n")
    assert_raises(Specifications::Error) { Document.reconcile!(@project) }
  end

  test "a feature dump can resume without creating another artifact" do
    runtime = DumpLoops::Runtime.new(project: @project, use_case_name: @feature.name)
    dump = runtime.open.dump
    dump.update!(status: "completed", capture_status: "closed")
    assert_no_difference "Dump.count" do
      resumed = DumpLoops::Runtime.new(project: @project, use_case_name: @feature.name).open.dump
      assert_equal dump.id, resumed.id
      assert resumed.capturing?
    end
    assert_raises(ActiveRecord::RecordInvalid) { @project.dumps.create!(use_case: @feature, title: "Duplicate") }
  end

  test "a conflicting ticket write cannot stamp execution into its tracker" do
    ticket = @board.tickets.create!(column: @ready, title: "Pending work", use_case: @feature)
    @tracker.generate!(specification: @specification, tickets: [ticket])
    path = Pathname.new(@project.root_path).join(ticket.relative_path)
    path.write(path.read + "\nExternal detail\n")
    assert_raises(Specifications::Error) { ticket.transition_to_column!(@working) }
    workflow = Features::Workflow.new(@feature)
    assert_nil workflow.tracker_entry[:metadata]["execution_started_at"]
    assert_not workflow.started?
  end

  private

  def harness_program(expression)
    path = Pathname.new(@project.root_path).join("harness-#{SecureRandom.hex(4)}")
    path.write(<<~RUBY)
      #!/usr/bin/env ruby
      require "json"
      context = JSON.parse(STDIN.read.split("Context:\\n", 2).last)
      value = begin
      #{expression}
      end
      File.write(ARGV[ARGV.index("--output-last-message") + 1], JSON.generate(value))
    RUBY
    path.chmod(0o700)
    path.to_s
  end
end
