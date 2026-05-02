require "test_helper"

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
end
