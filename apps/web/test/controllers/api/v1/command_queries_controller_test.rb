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
    assert_equal "Guided alignment is ready to continue.", body.fetch("next_prompt")
    assert body.fetch("session_id")
    assert body.fetch("project_id")
    assert_equal ["project_setup_session_written", "project_created"], body.fetch("effects").map { |effect| effect.fetch("type") }
  end

  test "advances project setup by recording a setup turn" do
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
    assert_equal "Project setup advanced.", body.fetch("summary")
    assert_equal "project_setup_turn_recorded", body.fetch("effects").first.fetch("type")
    assert_equal 1, session.reload.turn_counter
    turn = session.project_setup_turns.order(:turn_index).last
    assert_equal "Operators need a short feedback loop.", turn.answer
    assert_equal({"target_users" => "operators"}, turn.normalized_fields)
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
