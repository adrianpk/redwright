module TicketManagement
  class MentionCaptureService
    HANDLE_PATTERN = /(?<![\w.])@([A-Za-z0-9][A-Za-z0-9_.-]*)/.freeze

    def initialize(comment:)
      @comment = comment
    end

    def call
      handles.each do |handle|
        comment.mentions.create!(mention_attrs_for(handle))
      end
    end

    private

    attr_reader :comment

    def handles
      comment.body.to_s.scan(HANDLE_PATTERN).flatten.map { |handle| normalize_handle(handle) }.uniq
    end

    def normalize_handle(handle)
      handle.downcase.sub(/[.]+$/, "")
    end

    def mention_attrs_for(handle)
      user = user_for(handle)
      return user_attrs(handle, user) if user
      return agent_attrs(handle) if handle.start_with?("agent")

      unresolved_attrs(handle)
    end

    def user_attrs(handle, user)
      user_id, email_address = user
      base_attrs(handle).merge(
        target_type: "user",
        target_id: user_id,
        display_label: email_address
      )
    end

    def agent_attrs(handle)
      base_attrs(handle).merge(
        target_type: "agent",
        target_id: nil,
        display_label: "@#{handle}"
      )
    end

    def unresolved_attrs(handle)
      base_attrs(handle).merge(
        target_type: "unresolved",
        target_id: nil,
        display_label: "@#{handle}"
      )
    end

    def base_attrs(handle)
      {
        ticket: comment.ticket,
        handle: handle
      }
    end

    def user_for(handle)
      users_by_handle[handle]
    end

    def users_by_handle
      @users_by_handle ||= User.pluck(:id, :email_address).each_with_object({}) do |(id, email_address), users|
        local_part = email_address.to_s.split("@").first.to_s.downcase
        users[local_part] ||= [ id, email_address ] if local_part.present?
      end
    end
  end
end
