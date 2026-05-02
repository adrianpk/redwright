module ProjectInitialization
  class Command
    attr_reader :project_name, :directory_name, :repository_input, :guided_alignment

    def initialize(project_name:, directory_name:, repository_input:, guided_alignment: nil)
      @project_name = project_name.to_s.strip
      @directory_name = directory_name.to_s.strip
      @repository_input = repository_input.to_s.strip
      @guided_alignment = guided_alignment
    end

    def valid?
      errors.empty?
    end

    def errors
      @errors ||= begin
        result = {}
        result[:project_name] = "can't be blank" if project_name.empty?
        result[:directory_name] = "can't be blank" if directory_name.empty?
        result[:repository_input] = "can't be blank" if repository_input.empty?
        if !guided_alignment.nil? && ![true, false].include?(guided_alignment)
          result[:guided_alignment] = "must be boolean when provided"
        end
        result
      end
    end

    def to_h
      {
        project_name: project_name,
        directory_name: directory_name,
        repository_input: repository_input,
        guided_alignment: guided_alignment
      }
    end
  end
end
