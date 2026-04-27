# frozen_string_literal: true

module Redwright
  class Paths
    attr_reader :root, :state_dir, :config_dir, :projects_root, :worktrees_root, :db_path

    def initialize(mode: :dev, pwd: Dir.pwd, home: Dir.home)
      @root = case mode
              when :dev
                File.join(pwd, "_workspace")
              when :real
                home
              else
                raise ArgumentError, "unsupported mode: #{mode}"
              end

      @state_dir = File.join(@root, ".redwright")
      @config_dir = File.join(@root, ".config", "redwright")
      @projects_root = File.join(@root, "redwright")
      @worktrees_root = File.join(@projects_root, ".worktrees")
      @db_path = File.join(@state_dir, "runtime.db")
    end
  end
end
