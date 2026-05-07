require "json"

class Quiz < ApplicationRecord
  STATUSES = %w[active paused archived].freeze

  belongs_to :project
  belongs_to :use_case, optional: true
  has_many :entries, class_name: "QuizEntry", dependent: :destroy

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :project_id, uniqueness: { conditions: -> { where(use_case_id: nil) }, if: -> { use_case_id.nil? } }
  validates :use_case_id, uniqueness: { scope: :project_id }, allow_nil: true
  validate :use_case_belongs_to_project

  scope :project_level, -> { where(use_case_id: nil) }
  scope :for_use_case, ->(use_case_id) { where(use_case_id: use_case_id) }

  def current_tags
    parse_json_array(current_tags_json)
  end

  def current_tags=(value)
    self.current_tags_json = JSON.generate(Array(value).map(&:to_s).map(&:strip).reject(&:blank?))
  end

  def current_prompt_intent
    parse_json_object(current_prompt_intent_json)
  end

  def current_prompt_intent=(value)
    self.current_prompt_intent_json = JSON.generate(normalize_hash(value))
  end

  def current_question_errors
    parse_json_array(current_question_errors_json)
  end

  def current_question_errors=(value)
    self.current_question_errors_json = JSON.generate(Array(value).map(&:to_s))
  end

  def current_question?
    current_question.present?
  end

  def store_current_question!(question:, tags:, prompt_intent:, fallback_reason:, errors:)
    update!(
      current_question: question.to_s,
      current_tags: tags,
      current_prompt_intent: prompt_intent,
      current_fallback_reason: fallback_reason.to_s,
      current_question_errors: errors,
      current_question_started_at: Time.current
    )
  end

  def clear_current_question!
    update!(
      current_question: nil,
      current_tags: [],
      current_prompt_intent: {},
      current_fallback_reason: "",
      current_question_errors: [],
      current_question_started_at: nil
    )
  end

  private

  def use_case_belongs_to_project
    return unless use_case
    return if use_case.project_id == project_id

    errors.add(:use_case, "must belong to the same project")
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

  def normalize_hash(value)
    return {} unless value.is_a?(Hash)

    value.transform_keys(&:to_s)
  end
end
