# frozen_string_literal: true

require_relative "planner_contract"

module Redwright
  class ActionNormalizer
    def normalize(actions)
      return [] if actions.nil?
      raise ArgumentError, "actions_not_array" unless actions.is_a?(Array)

      normalized = []
      actions.each do |action|
        normalized.concat(expand_action(action))
      end
      normalized
    end

    private

    def expand_action(action)
      raise ArgumentError, "action_not_object" unless action.is_a?(Hash)

      case action["type"]
      when "write_files"
        raise ArgumentError, "macro_type_not_allowed" unless PlannerContract.macro_action_type?(action["type"])
        expand_write_files(action)
      when "run_command"
        raise ArgumentError, "macro_type_not_allowed" unless PlannerContract.macro_action_type?(action["type"])
        [build_run_action(action, suffix: nil, command: fetch_string(action.fetch("args", {}), "cmd", "run_command_missing_cmd"))]
      when "run_commands"
        raise ArgumentError, "macro_type_not_allowed" unless PlannerContract.macro_action_type?(action["type"])
        expand_run_commands(action)
      else
        [action]
      end
    end

    def expand_write_files(action)
      args = action.fetch("args", {})
      files = args["files"]
      raise ArgumentError, "write_files_missing_files" unless files.is_a?(Hash) && !files.empty?

      files.keys.sort.map.with_index do |path, idx|
        content = files[path]
        raise ArgumentError, "write_files_invalid_content" unless content.is_a?(String)

        build_action(
          action: action,
          suffix: idx + 1,
          type: "write_file",
          args: { "path" => path, "content" => content }
        )
      end
    end

    def expand_run_commands(action)
      args = action.fetch("args", {})
      cmds = args["cmds"]
      raise ArgumentError, "run_commands_missing_cmds" unless cmds.is_a?(Array) && !cmds.empty?

      cmds.map.with_index do |cmd, idx|
        raise ArgumentError, "run_commands_invalid_cmd" unless cmd.is_a?(String) && !cmd.strip.empty?

        build_run_action(action, suffix: idx + 1, command: cmd)
      end
    end

    def build_run_action(action, suffix:, command:)
      build_action(
        action: action,
        suffix: suffix,
        type: "run",
        args: { "command" => command }
      )
    end

    def build_action(action:, suffix:, type:, args:)
      id = action["id"].to_s.strip
      raise ArgumentError, "action_missing_id" if id.empty?

      expanded = action.dup
      expanded["id"] = suffix.nil? ? id : "#{id}.#{suffix}"
      expanded["type"] = type
      expanded["args"] = args
      expanded
    end

    def fetch_string(hash, key, error)
      value = hash[key]
      raise ArgumentError, error unless value.is_a?(String) && !value.strip.empty?

      value
    end
  end
end
