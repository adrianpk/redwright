require "fileutils"

module ProjectSetup
  class WorkspaceDirectory
    def self.ensure!(project)
      root = project.protocol_files.root
      return root if root.directory?
      unless project.root_path.start_with?("/workspace/projects/")
        raise Specifications::Error, "The project workspace is unavailable."
      end
      parent = ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"].presence ||
        (Rails.env.test? ? Rails.root.join("tmp", "redwright-local-projects") : Rails.root.join("..", "..", "_workspace", "Projects"))
      root = Pathname.new(parent).join(Pathname.new(project.root_path).basename).expand_path
      FileUtils.mkdir_p(root)
      project.update!(root_path: root.to_s)
      root
    end
  end
end
