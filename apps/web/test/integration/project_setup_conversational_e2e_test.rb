require "test_helper"
require "socket"
require "tmpdir"

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
    protocols_state = completed.fetch("data").fetch("protocols")
    assert_equal "draft", protocols_state.fetch("status")
    assert_equal "AGENTS.md", protocols_state.fetch("documents").first.fetch("path")
    assert_includes completed.dig("data", "protocols_generation", "stack_keys"), "ruby"
    assert_equal "rich-service", project.name
    assert_equal "Rails", project.project_attributes.find_by!(key: "setup_context.framework").value
    assert_equal "SQLite", project.project_attributes.find_by!(key: "setup_context.libraries").value
    assert_equal "agent_assisted", project.project_attributes.find_by!(key: "setup_context.agent_workflow_mode").value
    ticket = Ticket.find(completed.dig("data", "starter_ticket_id"))
    assert_equal "Prepare initial implementation plan", ticket.title
    assert_equal "backlog", ticket.column.key
    assert_equal ["Project Setup Summary"], ticket.documents.pluck(:title)
  end

  test "go cli setup initializes runtime containers and gates ticket execution until ready" do
    start = command(
      "StartProjectSetup",
      {
        project_name: "go-runtime-e2e",
        description: "A small Go CLI with Runtime Containers setup.",
        guided_alignment: true
      },
      request_id: request_id("go-runtime-start")
    )

    completed = command(
      "AdvanceProjectSetup",
      {
        session_id: start.fetch("session_id"),
        answer: "Go CLI using the standard library.",
        normalized_fields: {
          project_type: "cli",
          language_runtime: "Go 1.26.2",
          framework: "none",
          libraries: "standard library"
        }
      },
      request_id: request_id("go-runtime-context")
    )

    assert_equal "completed", completed.fetch("state")
    project = Project.find(completed.fetch("project_id"))
    runtime_state = completed.fetch("data").fetch("runtime_containers")
    assert_equal "go_cli", runtime_state.fetch("profile")
    assert_equal "generated", runtime_state.fetch("readiness")
    assert_equal "not_run", runtime_state.fetch("validation_status")
    assert_equal "deterministic_go_cli_generator", completed.dig("data", "runtime_containers_generation", "generator_source")
    readiness_ticket = Ticket.find(completed.dig("data", "runtime_containers_readiness_ticket_id"))
    assert_equal "Review Runtime Containers readiness", readiness_ticket.title

    blocked = command(
      "StartTicketExecution",
      {ticket_id: completed.dig("data", "starter_ticket_id")},
      request_id: request_id("go-runtime-blocked"),
      response_status: :unprocessable_entity
    )
    assert_equal "runtime_containers_not_ready", blocked.fetch("errors").first.fetch("code")
    assert_equal "generated", blocked.dig("errors", 0, "details", "runtime_containers", "readiness")

    generated_files = project.runtime_container.generated_files.map { |file| file.merge("status" => "accepted") }
    command(
      "UpdateProjectRuntimeContainers",
      {
        project_id: project.id,
        runtime_containers: {
          generated_files: generated_files,
          provenance: project.runtime_container.provenance.merge("generated_files_decision" => "accepted")
        }
      },
      request_id: request_id("go-runtime-accept-files")
    )
    command(
      "RecordProjectRuntimeContainerValidation",
      {
        project_id: project.id,
        validation_status: "skipped",
        validation_output_summary: "Go CLI scaffold validation accepted for setup e2e."
      },
      request_id: request_id("go-runtime-validation")
    )
    ready = command(
      "MarkProjectRuntimeContainersReady",
      {project_id: project.id},
      request_id: request_id("go-runtime-ready")
    )
    assert_equal "ready", ready.dig("data", "runtime_containers", "readiness")

    with_runtime_socket_response(
      {
        "status" => "ok",
        "project_id" => project.root_path,
        "workstream_id" => "ws-go-runtime-e2e",
        "task_id" => "task-go-runtime-e2e",
        "state" => "executing"
      }
    ) do |runtime_request|
      started = command(
        "StartTicketExecution",
        {ticket_id: completed.dig("data", "starter_ticket_id")},
        request_id: request_id("go-runtime-start-ticket")
      )
      captured_request = runtime_request.call

      assert_equal "ticket_execution_started", started.fetch("effects").first.fetch("type")
      assert_equal "ready", captured_request.dig("payload", "runtime_context", "runtime_containers", "readiness")
      assert_equal project.runtime_container.id, captured_request.dig("payload", "runtime_context", "runtime_containers", "configuration_id")
    end
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

  def command(name, payload, request_id:, response_status: :success)
    post "/api/v1/commands",
      params: {
        name: name,
        payload: payload,
        request_id: request_id
      },
      headers: actor_headers,
      as: :json
    assert_response response_status
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
        client.close
      end

      yield -> {
        thread.join(2)
        captured_request
      }
    ensure
      server&.close
      thread&.kill if thread&.alive?
      if previous_socket.nil?
        ENV.delete("REDWRIGHT_RUNTIME_SOCKET_PATH")
      else
        ENV["REDWRIGHT_RUNTIME_SOCKET_PATH"] = previous_socket
      end
    end
  end
end
