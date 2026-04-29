# frozen_string_literal: true

module Redwright
  class TelegramControlRouter
    def control_from_decision(decision, raw_text:)
      return nil unless decision.respond_to?(:intent) && decision.intent.to_s.strip == "meta"

      intent = if decision.respond_to?(:control_intent)
                 decision.control_intent.to_s.strip
               else
                 "none"
               end
      command = control_intent_command_map[intent]
      command ||= inferred_control_command(raw_text) if intent == "none"
      return nil if command.nil?

      { command: command, reason: raw_text.to_s.strip }
    end

    def control_from_operational(decision, raw_text:)
      return nil unless decision.respond_to?(:operational_intent)

      intent = decision.operational_intent.to_s.strip
      return nil if intent.empty? || intent == "none"

      map = {
        "task_pause" => "pause",
        "task_resume" => "resume",
        "task_cancel" => "stop",
        "plan_continue" => "resume",
        "plan_stop_and_apply" => "resume"
      }
      command = map[intent]
      return nil unless command

      { command: command, reason: raw_text.to_s.strip }
    end

    def parse_slash_command(text)
      raw = text.to_s.strip
      return nil unless raw.start_with?("/")

      command, *rest = raw.split(/\s+/, 2)
      arg = rest.first.to_s.strip

      case command.downcase
      when "/pause"
        { kind: "control", command: "pause", reason: raw }
      when "/resume"
        { kind: "control", command: "resume", reason: raw }
      when "/cancel"
        { kind: "control", command: "stop", reason: raw }
      when "/continue"
        { kind: "planner_hint", planner_text: "Continue with current context and execute using existing assumptions." }
      when "/status"
        { kind: "planner_hint", planner_text: "Show runtime status for the current active project and workstream." }
      when "/project"
        return { kind: "clarify", question: "Please provide a project name: /project new <name>." } if arg.match?(/^new$/i)
        if arg.match?(/^switch\s+/i)
          name = arg.sub(/^switch\s+/i, "")
          return {
            kind: "operational",
            command: "project_switch",
            planner_text_fallback: "Switch active project to #{name}."
          }
        end
        if arg.match?(/^new\s+/i)
          name = arg.sub(/^new\s+/i, "")
          return {
            kind: "operational",
            command: "project_new",
            planner_text_fallback: "Create a new project named #{name} and set it active."
          }
        end
        return { kind: "planner_hint", planner_text: "List known projects and show aliases." } if arg.match?(/^list$/i)
        return { kind: "planner_hint", planner_text: "Show the current active project id, alias, and workspace path." } if arg.match?(/^where$/i)
        nil
      when "/repo"
        if arg.match?(/^clone\s+/i)
          repo = arg.sub(/^clone\s+/i, "")
          return {
            kind: "operational",
            command: "repo_clone",
            planner_text_fallback: "Clone repository #{repo} into the workspace and register it as a project."
          }
        end
        return { kind: "planner_hint", planner_text: "Show repository status for the active project, including branch and dirty files." } if arg.match?(/^status$/i)
        if arg.match?(/^undo$/i)
          return {
            kind: "operational",
            command: "repo_undo",
            planner_text_fallback: "Undo the latest safe repository changes in the active project using runtime guardrails."
          }
        end
        nil
      when "/task"
        return { kind: "control", command: "pause", reason: raw } if arg.match?(/^pause$/i)
        return { kind: "control", command: "resume", reason: raw } if arg.match?(/^resume$/i)
        return { kind: "control", command: "stop", reason: raw } if arg.match?(/^cancel$/i)
        nil
      when "/plan"
        return { kind: "planner_hint", planner_text: "Start an explicit planning and slicing workflow for the current request." } if arg.match?(/^start$/i)
        return { kind: "planner_hint", planner_text: "Continue with current context and execute using existing assumptions." } if arg.match?(/^continue$/i)
        return { kind: "planner_hint", planner_text: "Stop asking clarification questions and continue implementation with the current accepted assumptions." } if arg.match?(/^stop-and-apply$/i)
        nil
      when "/trace"
        return { kind: "planner_hint", planner_text: "Enable runtime trace output for this session." } if arg.match?(/^on$/i)
        return { kind: "planner_hint", planner_text: "Disable runtime trace output for this session." } if arg.match?(/^off$/i)
        return { kind: "planner_hint", planner_text: "Show current runtime trace status for this session." } if arg.match?(/^status$/i)
        nil
      when "/help"
        { kind: "planner_hint", planner_text: "Show help for runtime commands: /project, /repo, /task, /plan, /trace, /skill." }
      when "/skills"
        { kind: "planner_hint", planner_text: "List available skills and how to trigger each one." }
      when "/skill"
        return { kind: "skill_control_stop", reason: raw } if arg.match?(/^stop-and-apply$/i)
        return nil if arg.empty?

        {
          kind: "skill",
          skill_name: arg,
          planner_text: "Activate skill '#{arg}' in explicit mode for this turn."
        }
      else
        nil
      end
    end

    private

    def control_intent_command_map
      {
        "proceed_with_current_context" => "resume",
        "cancel_task" => "stop",
        "cancel_all" => "stop"
      }
    end

    def inferred_control_command(raw_text)
      text = raw_text.to_s.strip.downcase
      return nil if text.empty?

      return "stop" if text.match?(/\A(cancel|cancelar|cancela|annulla|annullare|stop|deten|detener|parar|para)\b/)
      return "pause" if text.match?(/\A(pause|pausa|pausar)\b/)
      return "resume" if text.match?(/\A(resume|resumir|continua|continuar|continue|proceed|segui|seguir)\b/)

      nil
    end
  end
end
