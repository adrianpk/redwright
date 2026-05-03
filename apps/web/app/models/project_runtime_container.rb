require "json"

class ProjectRuntimeContainer < ApplicationRecord
  STATUSES = %w[draft active archived].freeze
  READINESS_STATES = %w[missing generated edited validated ready blocked].freeze
  VALIDATION_STATES = %w[not_run passed failed skipped stale].freeze
  VALIDATION_STALE_SOURCE_STATES = %w[passed skipped].freeze
  ARRAY_FIELDS = {
    "system_packages" => "system_packages_json",
    "dependency_commands" => "dependency_commands_json",
    "test_commands" => "test_commands_json",
    "lint_commands" => "lint_commands_json",
    "build_commands" => "build_commands_json",
    "format_commands" => "format_commands_json",
    "cache_mounts" => "cache_mounts_json",
    "secret_placeholders" => "secret_placeholders_json",
    "generated_files" => "generated_files_json",
    "assumptions" => "assumptions_json",
    "missing_information" => "missing_information_json",
    "risks" => "risks_json"
  }.freeze
  HASH_FIELDS = {
    "repository_mount" => "repository_mount_json",
    "environment" => "environment_json",
    "network_policy" => "network_policy_json",
    "user_policy" => "user_policy_json",
    "provenance" => "provenance_json"
  }.freeze
  READINESS_CRITICAL_ATTRIBUTES = %w[
    base_image
    runtime_name
    runtime_version
    working_directory
    system_packages_json
    dependency_commands_json
    test_commands_json
    lint_commands_json
    build_commands_json
    format_commands_json
    repository_mount_json
    cache_mounts_json
    environment_json
    secret_placeholders_json
    network_policy_json
    user_policy_json
    validation_command
    generated_files_json
  ].freeze

  belongs_to :project

  validates :profile, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :readiness, inclusion: { in: READINESS_STATES }
  validates :validation_status, inclusion: { in: VALIDATION_STATES }

  before_validation :set_defaults
  before_validation :mark_validation_stale_after_readiness_critical_change

  ARRAY_FIELDS.each do |field_name, column_name|
    define_method(field_name) do
      parse_json_array(public_send(column_name))
    end

    define_method("#{field_name}=") do |value|
      public_send("#{column_name}=", JSON.generate(normalize_array(value)))
    end
  end

  HASH_FIELDS.each do |field_name, column_name|
    define_method(field_name) do
      parse_json_object(public_send(column_name))
    end

    define_method("#{field_name}=") do |value|
      public_send("#{column_name}=", JSON.generate(normalize_hash(value)))
    end
  end

  def self.missing_state_for(project)
    {
      "id" => nil,
      "project_id" => project.id,
      "profile" => "default",
      "status" => "missing",
      "readiness" => "missing",
      "base_image" => nil,
      "runtime_name" => nil,
      "runtime_version" => nil,
      "working_directory" => nil,
      "system_packages" => [],
      "dependency_commands" => [],
      "test_commands" => [],
      "lint_commands" => [],
      "build_commands" => [],
      "format_commands" => [],
      "repository_mount" => {},
      "cache_mounts" => [],
      "environment" => {},
      "secret_placeholders" => [],
      "network_policy" => {},
      "user_policy" => {},
      "validation_command" => nil,
      "validation_status" => "not_run",
      "validation_output_summary" => nil,
      "generated_files" => [],
      "provenance" => {},
      "assumptions" => [],
      "missing_information" => [],
      "risks" => [],
      "created_at" => nil,
      "updated_at" => nil
    }
  end

  def to_state
    {
      "id" => id,
      "project_id" => project_id,
      "profile" => profile,
      "status" => status,
      "readiness" => readiness,
      "base_image" => base_image,
      "runtime_name" => runtime_name,
      "runtime_version" => runtime_version,
      "working_directory" => working_directory,
      "system_packages" => system_packages,
      "dependency_commands" => dependency_commands,
      "test_commands" => test_commands,
      "lint_commands" => lint_commands,
      "build_commands" => build_commands,
      "format_commands" => format_commands,
      "repository_mount" => repository_mount,
      "cache_mounts" => cache_mounts,
      "environment" => environment,
      "secret_placeholders" => secret_placeholders,
      "network_policy" => network_policy,
      "user_policy" => user_policy,
      "validation_command" => validation_command,
      "validation_status" => validation_status,
      "validation_output_summary" => validation_output_summary,
      "generated_files" => generated_files,
      "provenance" => provenance,
      "assumptions" => assumptions,
      "missing_information" => missing_information,
      "risks" => risks,
      "created_at" => created_at&.iso8601,
      "updated_at" => updated_at&.iso8601
    }
  end

  private

  def set_defaults
    self.profile = "default" if profile.blank?
    self.status = "draft" if status.blank?
    self.readiness = "missing" if readiness.blank?
    self.validation_status = "not_run" if validation_status.blank?
    ARRAY_FIELDS.each_value do |column_name|
      public_send("#{column_name}=", "[]") if public_send(column_name).blank?
    end
    HASH_FIELDS.each_value do |column_name|
      public_send("#{column_name}=", "{}") if public_send(column_name).blank?
    end
  end

  def mark_validation_stale_after_readiness_critical_change
    return unless persisted?
    return unless VALIDATION_STALE_SOURCE_STATES.include?(validation_status_in_database)
    return if explicit_validation_status_change?
    return unless READINESS_CRITICAL_ATTRIBUTES.any? { |attribute| will_save_change_to_attribute?(attribute) }

    self.validation_status = "stale"
  end

  def explicit_validation_status_change?
    will_save_change_to_validation_status? && validation_status != validation_status_in_database
  end

  def parse_json_array(raw)
    parsed = JSON.parse(raw.to_s)
    parsed.is_a?(Array) ? parsed : []
  rescue JSON::ParserError
    []
  end

  def parse_json_object(raw)
    parsed = JSON.parse(raw.to_s)
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError
    {}
  end

  def normalize_array(value)
    return value.map { |item| normalize_json_value(item) } if value.is_a?(Array)

    []
  end

  def normalize_hash(value)
    return {} unless value.is_a?(Hash)

    value.each_with_object({}) do |(key, item), hash|
      hash[key.to_s] = normalize_json_value(item)
    end
  end

  def normalize_json_value(value)
    case value
    when Hash
      normalize_hash(value)
    when Array
      value.map { |item| normalize_json_value(item) }
    else
      value
    end
  end
end
