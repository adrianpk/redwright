# frozen_string_literal: true

module Redwright
  class ProjectNewMediator
    def parse_operational_intent(intent:, args:)
      op = intent.to_s.strip
      return nil unless op == "project_new"

      operational_args = args.is_a?(Hash) ? args : {}
      name = operational_args["project_name"].to_s.strip
      name = operational_args["project_ref"].to_s.strip if name.empty?
      name = operational_args["name"].to_s.strip if name.empty?
      return nil if name.empty?

      { command: "new", name: name }
    end

    def parse_project_slash(raw:)
      text = raw.to_s.strip
      match = text.match(%r{\A/project\s+new\s+([a-zA-Z0-9._\-]+)\s*\z}i)
      return nil unless match

      { command: "new", name: match[1] }
    end
  end
end
