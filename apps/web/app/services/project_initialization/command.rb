module ProjectInitialization
  class Command
    attr_reader :project_name, :directory_name, :repository_input, :description, :guided_alignment

    def initialize(project_name:, directory_name: nil, repository_input: nil, description: nil, guided_alignment: nil)
      @project_name = project_name.to_s.strip
      @directory_name = directory_name.to_s.strip
      @directory_name = default_directory_name(@project_name) if @directory_name.empty? && !@project_name.empty?
      @repository_input = repository_input.to_s.strip
      @description = description.to_s.strip
      @guided_alignment = guided_alignment
    end

    def valid?
      errors.empty?
    end

    def errors
      @errors ||= begin
        result = {}
        if !guided_alignment.nil? && ![true, false].include?(guided_alignment)
          result[:guided_alignment] = "must be boolean when provided"
        end
        result
      end
    end

    def ready_for_repository_resolution?
      !project_name.empty? && !directory_name.empty? && !repository_input.empty?
    end

    def missing_context_slots
      slots = []
      slots << "project_name" if project_name.empty?
      slots
    end

    def to_h
      {
        project_name: project_name,
        directory_name: directory_name,
        repository_input: repository_input,
        description: description,
        guided_alignment: guided_alignment
      }
    end

    private

    def default_directory_name(value)
      value.to_s.downcase.gsub(/[^a-z0-9._-]+/, "-").gsub(/\A-+|-+\z/, "")
    end
  end
end
