require "test_helper"
require "socket"
require "tmpdir"

class Api::V1::CommandQueriesControllerTest < ActionDispatch::IntegrationTest
  test "requires actor context" do
    post "/api/v1/queries",
      params: {
        name: "ListProjects",
        payload: {},
        request_id: "req-missing-actor"
      },
      as: :json

    assert_response :unauthorized
    assert_equal "error", json_body.fetch("status")
    assert_equal "req-missing-actor", json_body.fetch("request_id")
    assert_equal "missing_actor_context", json_body.fetch("errors").first.fetch("code")
  end

  test "starts project setup through command api" do
    slug = "api-inventory-#{SecureRandom.hex(4)}"

    post "/api/v1/commands",
      params: {
        name: "StartProjectSetup",
        payload: {
          project_name: "API Inventory",
          directory_name: slug,
          repository_input: "acme/#{slug}",
          guided_alignment: true
        },
        request_id: "req-start"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    body = json_body
    assert_equal "ok", body.fetch("status")
    assert_equal "req-start", body.fetch("request_id")
    assert_equal "collecting_alignment", body.fetch("state")
    assert_equal "Project created; guided alignment is ready to continue.", body.fetch("summary")
    assert_equal ProjectSetup::GuidedAlignmentService.first_question, body.fetch("next_prompt")
    assert body.fetch("session_id")
    assert body.fetch("project_id")
    assert_equal ["project_setup_session_written", "project_created"], body.fetch("effects").map { |effect| effect.fetch("type") }
  end

  test "starts project setup context without repository input through command api" do
    post "/api/v1/commands",
      params: {
        name: "StartProjectSetup",
        payload: {
          project_name: "Notes CLI",
          description: "A small local notes manager",
          guided_alignment: true
        },
        request_id: "req-start-context"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    body = json_body
    assert_equal "ok", body.fetch("status")
    assert_equal "req-start-context", body.fetch("request_id")
    assert_equal "collecting_context", body.fetch("state")
    assert_equal "Project setup started.", body.fetch("summary")
    assert_nil body.fetch("next_prompt")
    assert body.fetch("session_id")
    assert_nil body.fetch("project_id")
    assert_equal ["project_setup_session_written"], body.fetch("effects").map { |effect| effect.fetch("type") }
    assert_equal(
      {"kind" => "setup_slot_question", "slot" => "project_type", "locale" => "auto", "llm_required" => true},
      body.fetch("data").fetch("next_prompt_intent")
    )
    slots = body.fetch("data").fetch("setup_context").fetch("slots")
    assert_equal "Notes CLI", slots.fetch("project_name").fetch("value")
    assert_equal "A small local notes manager", slots.fetch("description").fetch("value")
    refute slots.key?("repository")
  end

  test "completes sparse project setup context through command api" do
    post "/api/v1/commands",
      params: {
        name: "StartProjectSetup",
        payload: {
          guided_alignment: true
        },
        request_id: "req-context-loop-start"
      },
      headers: actor_headers,
      as: :json
    assert_response :success
    session_id = json_body.fetch("session_id")
    assert_equal(
      {"kind" => "setup_slot_question", "slot" => "project_name", "locale" => "auto", "llm_required" => true},
      json_body.fetch("data").fetch("next_prompt_intent")
    )

    post "/api/v1/commands",
      params: {
        name: "AdvanceProjectSetup",
        payload: {
          session_id: session_id,
          answer: "pocket-ledger"
        },
        request_id: "req-context-loop-name"
      },
      headers: actor_headers,
      as: :json
    assert_response :success
    assert_equal(
      {"kind" => "setup_slot_question", "slot" => "description", "locale" => "auto", "llm_required" => true},
      json_body.fetch("data").fetch("next_prompt_intent")
    )

    post "/api/v1/commands",
      params: {
        name: "AdvanceProjectSetup",
        payload: {
          session_id: session_id,
          answer: "A compact ledger for local expense notes."
        },
        request_id: "req-context-loop-description"
      },
      headers: actor_headers,
      as: :json
    assert_response :success
    assert_equal(
      {"kind" => "setup_slot_question", "slot" => "project_type", "locale" => "auto", "llm_required" => true},
      json_body.fetch("data").fetch("next_prompt_intent")
    )

    post "/api/v1/commands",
      params: {
        name: "AdvanceProjectSetup",
        payload: {
          session_id: session_id,
          answer: "CLI"
        },
        request_id: "req-context-loop-type"
      },
      headers: actor_headers,
      as: :json
    assert_response :success
    assert_equal(
      {"kind" => "setup_slot_question", "slot" => "language_runtime", "locale" => "auto", "llm_required" => true},
      json_body.fetch("data").fetch("next_prompt_intent")
    )

    post "/api/v1/commands",
      params: {
        name: "AdvanceProjectSetup",
        payload: {
          session_id: session_id,
          answer: "Ruby 3.4"
        },
        request_id: "req-context-loop-language"
      },
      headers: actor_headers,
      as: :json
    assert_response :success
    assert_equal(
      {"kind" => "setup_slot_question", "slot" => "framework", "locale" => "auto", "llm_required" => true},
      json_body.fetch("data").fetch("next_prompt_intent")
    )

    post "/api/v1/commands",
      params: {
        name: "AdvanceProjectSetup",
        payload: {
          session_id: session_id,
          answer: "none"
        },
        request_id: "req-context-loop-framework"
      },
      headers: actor_headers,
      as: :json
    assert_response :success
    assert_equal(
      {"kind" => "setup_slot_question", "slot" => "libraries", "locale" => "auto", "llm_required" => true},
      json_body.fetch("data").fetch("next_prompt_intent")
    )

    post "/api/v1/commands",
      params: {
        name: "AdvanceProjectSetup",
        payload: {
          session_id: session_id,
          answer: "Thor and SQLite"
        },
        request_id: "req-context-loop-libraries"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    body = json_body
    session = ProjectSetupSession.find(session_id)
    assert_equal "completed", body.fetch("state")
    assert_equal "Project created; setup completed.", body.fetch("summary")
    assert_equal "completed_without_alignment", body.dig("data", "terminal_reason")
    assert body.fetch("project_id")
    assert_equal 6, session.reload.turn_counter
    assert_equal "pocket-ledger", session.project.name
    assert_equal "ruby-3.4", session.project.stack_slug
    assert session.project.documents.exists?(title: "Project Setup Summary", artifact_type: "draft")
    assert session.project.boards.exists?(name: "pocket-ledger Board")
    assert_equal %w[backlog in_progress review approved merged], session.project.boards.first.columns.order(:position).pluck(:key)
    assert_equal(
      %w[
        setup_context.agent_workflow_mode
        setup_context.description
        setup_context.framework
        setup_context.language_runtime
        setup_context.libraries
        setup_context.project_name
        setup_context.project_type
        setup_context.runtime_container_profile
        setup_context.stack
      ],
      session.project.project_attributes.order(:key).pluck(:key)
    )
    assert_equal(
      [
        "project_setup_turn_recorded",
        "project_created",
        "setup_context_materialized",
        "setup_summary_document_written",
        "default_board_structure_written",
        "project_setup_completed"
      ],
      body.fetch("effects").map { |effect| effect.fetch("type") }
    )
  end

  test "done completes project setup with defaults after project name" do
    post "/api/v1/commands",
      params: {
        name: "StartProjectSetup",
        payload: {
          project_name: "tiny-index",
          guided_alignment: true
        },
        request_id: "req-context-done-start"
      },
      headers: actor_headers,
      as: :json
    assert_response :success
    session_id = json_body.fetch("session_id")

    post "/api/v1/commands",
      params: {
        name: "AdvanceProjectSetup",
        payload: {
          session_id: session_id,
          answer: "/done"
        },
        request_id: "req-context-done"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    session = ProjectSetupSession.find(session_id)
    assert_equal "completed", json_body.fetch("state")
    assert_equal "Project initialized from conversational setup.", session.setup_slot("description").fetch("value")
    assert_equal "defaulted", session.setup_slot("description").fetch("status")
    assert_equal "ruby", session.setup_slot("stack").fetch("value")
    assert_equal "defaulted", session.setup_slot("stack").fetch("status")
    assert_equal "tiny-index", session.project.name
  end

  test "skip cannot bypass blocking project name and cancel leaves no project" do
    post "/api/v1/commands",
      params: {
        name: "StartProjectSetup",
        payload: {
          guided_alignment: true
        },
        request_id: "req-context-control-start"
      },
      headers: actor_headers,
      as: :json
    assert_response :success
    session_id = json_body.fetch("session_id")

    assert_no_difference -> { Project.count } do
      post "/api/v1/commands",
        params: {
          name: "AdvanceProjectSetup",
          payload: {
            session_id: session_id,
            answer: "/skip"
          },
          request_id: "req-context-skip-blocking"
        },
        headers: actor_headers,
        as: :json
    end
    assert_response :success
    assert_equal "collecting_context", json_body.fetch("state")
    assert_equal "project_name", json_body.fetch("data").fetch("next_prompt_intent").fetch("slot")

    assert_no_difference -> { Project.count } do
      post "/api/v1/commands",
        params: {
          name: "AdvanceProjectSetup",
          payload: {
            session_id: session_id,
            answer: "/cancel"
          },
          request_id: "req-context-cancel"
        },
        headers: actor_headers,
        as: :json
    end
    assert_response :success
    assert_equal "cancelled", json_body.fetch("state")
    assert_equal "cancelled_by_user", ProjectSetupSession.find(session_id).terminal_reason
  end

  test "advances guided alignment by recording one setup turn and returning the next question" do
    session = started_alignment_session

    post "/api/v1/commands",
      params: {
        name: "AdvanceProjectSetup",
        payload: {
          session_id: session.id,
          answer: "Operators need a short feedback loop.",
          normalized_fields: {
            target_users: "operators"
          }
        },
        request_id: "req-advance"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    body = json_body
    assert_equal "ok", body.fetch("status")
    assert_equal session.id, body.fetch("session_id")
    assert_equal "collecting_alignment", body.fetch("state")
    assert_equal "Guided alignment advanced.", body.fetch("summary")
    assert_equal ProjectSetup::GuidedAlignmentService::QUESTIONS.fetch(1).fetch("question"), body.fetch("next_prompt")
    assert_equal "project_setup_turn_recorded", body.fetch("effects").first.fetch("type")
    assert_equal 1, session.reload.turn_counter
    turn = session.project_setup_turns.order(:turn_index).last
    assert_equal "Operators need a short feedback loop.", turn.answer
    assert_equal "primary_outcome", turn.normalized_fields.fetch("alignment_key")
    assert_equal "operators", turn.normalized_fields.fetch("target_users")
  end

  test "completes guided alignment through api with bounded turns and artifacts" do
    session = started_alignment_session
    answers = [
      "Optimize for clear project setup.",
      "Developers and reviewer agents.",
      "Keep review gates explicit."
    ]

    answers.each_with_index do |answer, index|
      post "/api/v1/commands",
        params: {
          name: "AdvanceProjectSetup",
          payload: {
            session_id: session.id,
            answer: answer
          },
          request_id: "req-complete-#{index}"
        },
        headers: actor_headers,
        as: :json

      assert_response :success
    end

    body = json_body
    assert_equal "completed", body.fetch("state")
    assert_equal "Guided alignment completed.", body.fetch("summary")
    assert_equal "completed_with_alignment", body.dig("data", "terminal_reason")
    assert body.dig("data", "alignment_document_id")
    assert_equal ["project_setup_turn_recorded", "guided_alignment_artifacts_written", "project_setup_completed"], body.fetch("effects").map { |effect| effect.fetch("type") }
    session.reload
    assert_equal 3, session.turn_counter
    assert_equal 3, session.project.project_attributes.where(source: "guided_alignment").count
    assert session.project.documents.exists?(title: "Guided Alignment Summary", artifact_type: "draft")

    post "/api/v1/commands",
      params: {
        name: "AdvanceProjectSetup",
        payload: {
          session_id: session.id,
          answer: "Another answer must not be accepted."
        },
        request_id: "req-after-terminal"
      },
      headers: actor_headers,
      as: :json

    assert_response :unprocessable_entity
    assert_equal "terminal_setup_session", json_body.fetch("errors").first.fetch("code")
  end

  test "replays guided alignment request id without duplicating turns" do
    session = started_alignment_session
    payload = {
      name: "AdvanceProjectSetup",
      payload: {
        session_id: session.id,
        answer: "Optimize for retries."
      },
      request_id: "req-replay"
    }

    post "/api/v1/commands", params: payload, headers: actor_headers, as: :json
    assert_response :success
    post "/api/v1/commands", params: payload, headers: actor_headers, as: :json
    assert_response :success

    body = json_body
    assert_equal "project_setup_turn_reused", body.fetch("effects").first.fetch("type")
    assert_equal 1, session.reload.turn_counter
    assert_equal 1, session.project_setup_turns.count
  end

  test "cancels project setup through command api" do
    session = ProjectSetupSession.create!(
      actor_identifier: "api:test",
      request_id: "req-seed-cancel",
      source_channel: "api"
    )

    post "/api/v1/commands",
      params: {
        name: "CancelProjectSetup",
        payload: {
          session_id: session.id
        },
        request_id: "req-cancel"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    body = json_body
    assert_equal "cancelled", body.fetch("state")
    assert_equal "Project setup cancelled.", body.fetch("summary")
    assert_equal "cancelled_by_user", session.reload.terminal_reason
    assert_equal "project_setup_cancelled", body.fetch("effects").first.fetch("type")
  end

  test "gets project setup session status through query api" do
    session = ProjectSetupSession.create!(
      actor_identifier: "api:test",
      request_id: "req-seed-status",
      source_channel: "api",
      pending_question: "Which repository?"
    )

    post "/api/v1/queries",
      params: {
        name: "GetProjectSetupSession",
        payload: {
          session_id: session.id
        },
        request_id: "req-status"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    body = json_body
    assert_equal "ok", body.fetch("status")
    assert_equal session.id, body.fetch("session_id")
    assert_equal "collecting_context", body.fetch("state")
    assert_equal "Which repository?", body.fetch("next_prompt")
    assert_equal "Project setup session retrieved.", body.fetch("summary")
  end

  test "lists projects through query api" do
    project = create_project(name: "API Listed Project", key: "api-listed-#{SecureRandom.hex(4)}")

    post "/api/v1/queries",
      params: {
        name: "ListProjects",
        payload: {},
        request_id: "req-list-projects"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    body = json_body
    assert_equal "ok", body.fetch("status")
    assert_equal "Projects retrieved.", body.fetch("summary")
    project_ids = body.fetch("data").fetch("projects").map { |item| item.fetch("id") }
    assert_includes project_ids, project.id
  end

  test "creates and promotes documents through command api" do
    project = create_project(key: "api-docs-#{SecureRandom.hex(4)}")

    post "/api/v1/commands",
      params: {
        name: "CreateDocument",
        payload: {
          project_id: project.id,
          title: "API Draft",
          body: "Draft body"
        },
        request_id: "req-api-doc-create"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    draft_id = json_body.fetch("data").fetch("document_id")

    post "/api/v1/commands",
      params: {
        name: "PromoteDraftToSpec",
        payload: {
          document_id: draft_id
        },
        request_id: "req-api-doc-promote"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    body = json_body
    assert_equal "Document draft promoted to spec.", body.fetch("summary")
    assert_equal "spec", body.fetch("data").fetch("document").fetch("artifact_type")
    assert_equal "document_promoted", body.fetch("effects").first.fetch("type")
  end

  test "creates moves attaches and snapshots tickets through command api" do
    board = create_board(project_key: "api-board-#{SecureRandom.hex(4)}")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    review = board.columns.create!(key: "review", title: "Review", position: 1)
    draft = create_document(project: board.project, title: "API Ticket Draft")

    post "/api/v1/commands",
      params: {
        name: "CreateTicket",
        payload: {
          board_id: board.id,
          column_id: backlog.id,
          title: "API Ticket",
          priority: "high"
        },
        request_id: "req-api-ticket-create"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    ticket_id = json_body.fetch("data").fetch("ticket_id")

    post "/api/v1/commands",
      params: {
        name: "AttachDocumentToTicket",
        payload: {
          ticket_id: ticket_id,
          document_id: draft.id
        },
        request_id: "req-api-ticket-attach"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    assert_equal "document_attached_to_ticket", json_body.fetch("effects").first.fetch("type")

    post "/api/v1/commands",
      params: {
        name: "MoveTicket",
        payload: {
          ticket_id: ticket_id,
          column_id: review.id
        },
        request_id: "req-api-ticket-move"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    assert_equal review.id, Ticket.find(ticket_id).column_id

    post "/api/v1/queries",
      params: {
        name: "GetBoard",
        payload: {
          board_id: board.id
        },
        request_id: "req-api-board"
      },
      headers: actor_headers,
      as: :json

    assert_response :success
    body = json_body
    review_column = body.fetch("data").fetch("board").fetch("columns").find { |column| column.fetch("key") == "review" }
    assert_equal [ticket_id], review_column.fetch("tickets").map { |ticket| ticket.fetch("id") }
    assert_equal [draft.id], review_column.fetch("tickets").first.fetch("document_links").map { |link| link.fetch("document_id") }
  end

  test "starts ticket execution through command api and records runtime correlation" do
    board = create_board(project_key: "api-runtime-#{SecureRandom.hex(4)}")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Runtime API Ticket", priority: :high)
    captured_request = nil

    with_runtime_socket_response(
      {
        "status" => "ok",
        "project_id" => board.project.root_path,
        "workstream_id" => "ws-api",
        "task_id" => "task-api",
        "state" => "executing"
      }
    ) do |runtime_request|
      post "/api/v1/commands",
        params: {
          name: "StartTicketExecution",
          payload: {
            ticket_id: ticket.id
          },
          request_id: "req-api-runtime-start"
        },
        headers: actor_headers,
        as: :json

      captured_request = runtime_request.call
    end

    assert_response :success
    body = json_body
    assert_equal "Ticket execution started.", body.fetch("summary")
    assert_equal "ticket_execution_started", body.fetch("effects").first.fetch("type")
    ticket.reload
    assert_equal "started", ticket.runtime_execution_status
    assert_equal "ws-api", ticket.runtime_workstream_id
    assert_equal "task-api", ticket.runtime_task_id
    assert_equal "executing", ticket.runtime_state
    assert_equal ticket.id, captured_request.dig("payload", "rails", "ticket_id")
    assert_includes captured_request.dig("payload", "message"), "Runtime API Ticket"
  end

  private

  def started_alignment_session
    slug = "api-advance-#{SecureRandom.hex(4)}"
    post "/api/v1/commands",
      params: {
        name: "StartProjectSetup",
        payload: {
          project_name: "API Advance",
          directory_name: slug,
          repository_input: "acme/#{slug}",
          guided_alignment: true
        },
        request_id: "req-start-for-advance"
      },
      headers: actor_headers,
      as: :json
    assert_response :success

    ProjectSetupSession.find(json_body.fetch("session_id"))
  end

  def actor_headers
    {
      "X-Redwright-Actor" => "telegram:42",
      "X-Redwright-Source" => "telegram"
    }
  end

  def json_body
    JSON.parse(response.body)
  end

  def with_runtime_socket_response(payload)
    previous_socket = ENV["REDWRIGHT_RUNTIME_SOCKET_PATH"]
    Dir.mktmpdir("redwright-runtime-socket-") do |dir|
      socket_path = File.join(dir, "rw.sock")
      ENV["REDWRIGHT_RUNTIME_SOCKET_PATH"] = socket_path
      server = UNIXServer.new(socket_path)
      captured_request = nil
      thread = Thread.new do
        client = server.accept
        line = client.gets
        captured_request = JSON.parse(line)
        client.write(
          JSON.generate(
            {
              "type" => "ack",
              "session_id" => captured_request.fetch("session_id"),
              "payload" => payload
            }
          ) + "\n"
        )
      ensure
        client&.close
      end

      yield -> { thread.join(1); captured_request }
      thread.join(1)
    ensure
      server&.close
      thread&.kill if thread&.alive?
      ENV["REDWRIGHT_RUNTIME_SOCKET_PATH"] = previous_socket
    end
  end
end
