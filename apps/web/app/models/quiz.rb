require "json"
require "securerandom"

class Quiz < ApplicationRecord
  STATUSES = %w[active paused archived].freeze
  MODES = %w[deep fast].freeze

  belongs_to :project
  belongs_to :use_case, optional: true
  has_many :entries, class_name: "QuizEntry", dependent: :destroy

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :mode, inclusion: { in: MODES }
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

  def candidate_questions
    parse_json_array(candidate_questions_json).filter_map do |candidate|
      normalize_candidate(candidate) if candidate.is_a?(Hash)
    end
  end

  def candidate_questions=(value)
    self.candidate_questions_json = JSON.generate(Array(value).filter_map do |candidate|
      normalize_candidate(candidate) if candidate.is_a?(Hash)
    end)
  end

  def add_candidate!(question:, tags:, prompt_intent:, fallback_reason: "", errors: [], parent_id: nil, branch_key: nil)
    candidate = normalize_candidate(
      "id" => SecureRandom.uuid,
      "question" => question.to_s.strip,
      "tags" => normalize_tags(tags),
      "prompt_intent" => normalize_hash(prompt_intent),
      "fallback_reason" => fallback_reason.to_s,
      "errors" => Array(errors).map(&:to_s),
      "parent_id" => parent_id.to_s.presence,
      "branch_key" => branch_key.to_s.presence,
      "status" => "active",
      "created_at" => Time.current.iso8601
    )
    update!(candidate_questions: candidate_questions + [candidate])
    candidate
  end

  def activate_candidate!(candidate_id)
    candidates = candidate_questions
    candidate = candidates.find { |item| item.fetch("id") == candidate_id.to_s && item.fetch("status") == "active" }
    return nil unless candidate

    now = Time.current.iso8601
    update!(
      current_question: candidate.fetch("question"),
      current_tags: candidate.fetch("tags"),
      current_prompt_intent: candidate.fetch("prompt_intent"),
      current_fallback_reason: candidate.fetch("fallback_reason"),
      current_question_errors: candidate.fetch("errors"),
      current_question_started_at: Time.current,
      candidate_questions: candidates.map { |item| activated_candidate_state(item, candidate, now) }
    )
    candidate
  end

  def cleanup_stale_candidates!(older_than: 24.hours)
    candidates = candidate_questions
    cutoff = Time.current - older_than
    retained = candidates.reject do |candidate|
      candidate.fetch("status") != "activated" && candidate_created_at(candidate) < cutoff
    end
    update!(candidate_questions: retained) if retained.length != candidates.length
  end

  def deep_mode?
    mode == "deep"
  end

  def fast_mode?
    mode == "fast"
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

  def normalize_candidate(candidate)
    normalized = normalize_hash(candidate)
    {
      "id" => normalized.fetch("id", SecureRandom.uuid).to_s,
      "question" => normalized.fetch("question", "").to_s.strip,
      "tags" => normalize_tags(normalized.fetch("tags", [])),
      "prompt_intent" => normalize_hash(normalized.fetch("prompt_intent", {})),
      "fallback_reason" => normalized.fetch("fallback_reason", "").to_s,
      "errors" => Array(normalized.fetch("errors", [])).map(&:to_s),
      "parent_id" => normalized["parent_id"].presence,
      "branch_key" => normalized["branch_key"].presence,
      "status" => normalized.fetch("status", "active").to_s,
      "created_at" => normalized.fetch("created_at", Time.current.iso8601).to_s,
      "activated_at" => normalized["activated_at"].presence,
      "discarded_at" => normalized["discarded_at"].presence,
      "discard_reason" => normalized["discard_reason"].presence
    }.compact
  end

  def normalize_tags(value)
    Array(value).map { |tag| Tag.normalize_name(tag) }.reject(&:blank?).uniq
  end

  def activated_candidate_state(candidate, activated_candidate, timestamp)
    return candidate.merge("status" => "activated", "activated_at" => timestamp) if candidate.fetch("id") == activated_candidate.fetch("id")
    return candidate unless sibling_candidate?(candidate, activated_candidate)

    candidate.merge("status" => "discarded", "discarded_at" => timestamp, "discard_reason" => "sibling_pruned")
  end

  def sibling_candidate?(candidate, activated_candidate)
    activated_candidate["parent_id"].present? &&
      candidate["parent_id"] == activated_candidate["parent_id"] &&
      candidate.fetch("status") == "active"
  end

  def candidate_created_at(candidate)
    Time.zone.parse(candidate.fetch("created_at"))
  rescue ArgumentError, TypeError
    Time.current
  end
end
