class Project < ApplicationRecord
  has_many :boards, dependent: :restrict_with_error
  has_many :project_attributes, dependent: :delete_all
  has_many :documents, dependent: :restrict_with_error
  has_many :project_setup_sessions, dependent: :restrict_with_error
  has_many :use_cases, dependent: :restrict_with_error
  has_many :quizzes, dependent: :restrict_with_error
  has_many :quiz_entries, dependent: :restrict_with_error
  has_one :protocol, class_name: "ProjectProtocol", dependent: :destroy
  has_one :runtime_container, class_name: "ProjectRuntimeContainer", dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true
  validates :root_path, presence: true, uniqueness: true
  validates :repo_url, presence: true, uniqueness: true
  validates :stack_slug, presence: true

  def boards_scope
    boards.order(:name)
  end

  def tickets_scope
    Ticket.for_project(id)
  end

  def documents_scope
    documents.order(updated_at: :desc, created_at: :desc)
  end

  def project_attributes_scope
    project_attributes.order(weight: :desc, updated_at: :desc)
  end

  def runtime_container_state
    runtime_container&.to_state || ProjectRuntimeContainer.missing_state_for(self)
  end

  def protocol_state
    protocol&.to_state || ProjectProtocol.missing_state_for(self)
  end
end
