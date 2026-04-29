# frozen_string_literal: true
require "pathname"

module Redwright
  class Paths
    attr_reader :root, :state_dir, :config_dir, :projects_root, :worktrees_root, :db_path
    RUNTIMES = %w[interactive factory].freeze

    def initialize(mode: :dev, pwd: Dir.pwd, home: Dir.home)
      @mode = mode
      case mode
      when :dev
        workspace_root = File.join(pwd, "_workspace")
        @root = workspace_root
        @state_dir = File.join(workspace_root, "redwright")
        @config_dir = File.join(workspace_root, "config", "redwright")
        @projects_root = File.join(workspace_root, "Projects")
      when :real
        @root = home
        @state_dir = File.join(home, ".redwright")
        @config_dir = File.join(home, ".config", "redwright")
        @projects_root = File.join(home, "Projects")
      else
        raise ArgumentError, "unsupported mode: #{mode}"
      end

      @worktrees_root = File.join(@projects_root, ".worktrees")
      @db_path = File.join(@state_dir, "runtime.db")
    end

    def resolve_projects_root(config_value)
      return @projects_root if dev_mode?

      raw = config_value.to_s.strip
      if raw.start_with?("~/")
        return File.expand_path(raw.sub("~/", ""), @root)
      end
      unless Pathname.new(raw).absolute?
        raise ArgumentError, "invalid config key: default_projects_root must be absolute in real mode"
      end

      File.expand_path(raw, @root)
    end

    def runtime_state_root(runtime)
      runtime_name = runtime.to_s
      unless RUNTIMES.include?(runtime_name)
        raise ArgumentError, "unsupported runtime: #{runtime_name}"
      end

      File.join(@state_dir, "runtimes", runtime_name)
    end

    private

    def dev_mode?
      @mode == :dev
    end
  end
end
