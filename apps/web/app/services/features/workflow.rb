require "fileutils"

module Features
  class Workflow
    def initialize(use_case)
      @use_case = use_case
    end

    def with_lock
      return yield unless @use_case
      root = ProjectProtocols::FileStore.for_project(@use_case.project).root
      directory = root.join(".rw")
      raise Specifications::Error, "Invalid feature lock directory." if directory.symlink?
      FileUtils.mkdir_p(directory)
      path = directory.join("feature-#{@use_case.slug}.lock")
      raise Specifications::Error, "Invalid feature lock file." if path.symlink?
      File.open(path, File::RDWR | File::CREAT, 0o600) do |lock|
        unless lock.flock(File::LOCK_EX | File::LOCK_NB)
          raise Specifications::Error.new("This feature is being updated. Try again after it finishes.", code: :conflict)
        end
        yield
      ensure
        lock.flock(File::LOCK_UN) if lock
      end
    end

    def started?
      return false unless @use_case
      Ticket.reconcile!(@use_case.project)
      Ticket.where(use_case_id: @use_case.id).any?(&:execution_started?) || tracker_entry&.dig(:metadata, "execution_started_at").present?
    end

    def ensure_mutable!
      if started?
        raise Specifications::Error, "Execution has started. Create a corrective use case linked to this feature."
      end
    end

    def invalidate_tracker!
      entry = tracker_entry
      return unless entry
      store.write(path: entry[:path], metadata: entry[:metadata].merge("status" => "needs_review"),
        body: entry[:body], revision: entry[:source_hash])
    end

    def ensure_start_allowed!(ticket)
      return if ticket.specification_path.blank?
      specification = store.read(ticket.specification_path)
      tracker = store.read(ticket.tracker_path)
      unless specification[:status].in?(%w[approved accepted final]) && tracker[:status] == "tracking" &&
          specification[:source_hash] == tracker[:metadata]["specification_revision"] &&
          specification[:source_hash] == ticket.specification_revision &&
          specification[:use_case_id] == @use_case.id && Array(tracker[:metadata]["ticket_keys"]).include?(ticket.ticket_key)
        raise Specifications::Error, "Review the specification and rebuild its slicing before starting this ticket."
      end
    end

    def mark_started!(ticket)
      return if ticket.specification_path.blank?
      tracker = store.read(ticket.tracker_path)
      return if tracker[:metadata]["execution_started_at"].present?
      store.write(path: tracker[:path], metadata: tracker[:metadata].merge("execution_started_at" => Time.current.iso8601),
        body: tracker[:body], revision: tracker[:source_hash])
    end

    def tracker_entry
      return nil unless @use_case
      store.entries.find { |entry| entry[:artifact_type] == "plan_tracker" && entry[:use_case_id] == @use_case.id }
    end

    private

    def store
      @store ||= Specifications::FileStore.new(@use_case.project)
    end
  end
end
