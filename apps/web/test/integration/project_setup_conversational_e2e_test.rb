require "test_helper"

class ProjectSetupConversationalE2eTest < ActionDispatch::IntegrationTest
  test "sparse setup starts without arguments and completes with defaults" do
    start = command("StartProjectSetup", {}, request_id: request_id("sparse-start"))

    assert_equal "ok", start.fetch("status")
    assert_equal "collecting_context", start.fetch("state")
    assert_equal "project_name", start.dig("data", "next_prompt_intent", "slot")
    session_id = start.fetch("session_id")

    name = command("AdvanceProjectSetup", {session_id: session_id, answer: "sparse-tool"}, request_id: request_id("sparse-name"))
    assert_equal "description", name.dig("data", "next_prompt_intent", "slot")

    completed = command("AdvanceProjectSetup", {session_id: session_id, answer: "/done"}, request_id: request_id("sparse-done"))

    assert_equal "ok", completed.fetch("status")
    assert_equal "completed", completed.fetch("state")
    session = ProjectSetupSession.find(session_id)
    assert_equal "sparse-tool", session.project.name
    assert_equal "Project initialized from conversational setup.", session.setup_slot("description").fetch("value")
    assert_equal "defaulted", session.setup_slot("runtime_container_profile").fetch("status")
    assert_equal "manual", session.setup_slot("agent_workflow_mode").fetch("value")
    ticket = session.project.tickets_scope.find_by!(title: "Prepare initial implementation plan")
    assert_equal completed.dig("data", "starter_ticket_id"), ticket.id
    assert_equal "materialized_planned", completed.dig("setup_saga", "materialization", "status")
    assert_equal "planned", completed.dig("setup_saga", "initial_implementation", "status")
  end

  test "rich setup materializes canonical context and starter workflow ticket" do
    start = command(
      "StartProjectSetup",
      {
        project_name: "rich-service",
        description: "A small API service for project setup coverage.",
        guided_alignment: true
      },
      request_id: request_id("rich-start")
    )
    assert_equal "project_type", start.dig("data", "next_prompt_intent", "slot")

    completed = command(
      "AdvanceProjectSetup",
      {
        session_id: start.fetch("session_id"),
        answer: "API service with Ruby on Rails and SQLite.",
        normalized_fields: {
          project_type: "api_service",
          language_runtime: "Ruby 3.4",
          framework: "Rails",
          libraries: "SQLite",
          agent_workflow_mode: "agent_assisted",
          runtime_container_profile: "ephemeral_docker"
        }
      },
      request_id: request_id("rich-context")
    )

    assert_equal "completed", completed.fetch("state")
    project = Project.find(completed.fetch("project_id"))
    assert_equal "rich-service", project.name
    assert_equal "Rails", project.project_attributes.find_by!(key: "setup_context.framework").value
    assert_equal "SQLite", project.project_attributes.find_by!(key: "setup_context.libraries").value
    assert_equal "agent_assisted", project.project_attributes.find_by!(key: "setup_context.agent_workflow_mode").value
    ticket = Ticket.find(completed.dig("data", "starter_ticket_id"))
    assert_equal "Prepare initial implementation plan", ticket.title
    assert_equal "backlog", ticket.column.key
    assert_equal ["Project Setup Summary"], ticket.documents.pluck(:title)
  end

  test "skip advances non-blocking slots and done completes with defaults" do
    start = command(
      "StartProjectSetup",
      {project_name: "skip-flow", guided_alignment: true},
      request_id: request_id("skip-start")
    )
    assert_equal "description", start.dig("data", "next_prompt_intent", "slot")

    skipped = command(
      "AdvanceProjectSetup",
      {session_id: start.fetch("session_id"), answer: "/skip"},
      request_id: request_id("skip-description")
    )
    assert_equal "project_type", skipped.dig("data", "next_prompt_intent", "slot")

    completed = command(
      "AdvanceProjectSetup",
      {session_id: start.fetch("session_id"), answer: "/done"},
      request_id: request_id("skip-done")
    )

    assert_equal "completed", completed.fetch("state")
    session = ProjectSetupSession.find(start.fetch("session_id"))
    assert_equal "skipped", session.setup_slot("description").fetch("status")
    assert_equal "application", session.setup_slot("project_type").fetch("value")
    assert_equal "skip-flow", session.project.name
  end

  test "cancel leaves only the auditable setup session" do
    start = command("StartProjectSetup", {}, request_id: request_id("cancel-start"))
    session_id = start.fetch("session_id")

    assert_no_difference -> { Project.count } do
      cancelled = command(
        "AdvanceProjectSetup",
        {session_id: session_id, answer: "/cancel"},
        request_id: request_id("cancel-command")
      )
      assert_equal "cancelled", cancelled.fetch("state")
    end

    session = ProjectSetupSession.find(session_id)
    assert_equal "cancelled", session.current_state
    assert_equal "cancelled_by_user", session.terminal_reason
    assert_nil session.project_id
  end

  test "repository backed setup creates the project without repository ambiguity" do
    slug = "repo-backed-#{SecureRandom.hex(4)}"
    body = command(
      "StartProjectSetup",
      {
        project_name: "Repo Backed",
        directory_name: slug,
        repository_input: "acme/#{slug}",
        guided_alignment: true
      },
      request_id: request_id("repo-backed")
    )

    assert_equal "ok", body.fetch("status")
    assert_equal "collecting_alignment", body.fetch("state")
    refute_equal "awaiting_repository", body.fetch("state")
    project = Project.find(body.fetch("project_id"))
    assert_equal "Repo Backed", project.name
    assert_match %r{acme/#{slug}}, project.repo_url
    assert_equal "Project created; guided alignment is ready to continue.", body.fetch("summary")
  end

  private

  def command(name, payload, request_id:)
    post "/api/v1/commands",
      params: {
        name: name,
        payload: payload,
        request_id: request_id
      },
      headers: actor_headers,
      as: :json
    assert_response :success
    JSON.parse(response.body)
  end

  def request_id(suffix)
    "req-project-setup-e2e-#{suffix}-#{SecureRandom.hex(4)}"
  end

  def actor_headers
    {
      "X-Redwright-Actor" => "telegram:e2e",
      "X-Redwright-Source" => "telegram"
    }
  end
end
