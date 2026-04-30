module BoardsHelper
  def seconds_to_readable(value)
    total = value.to_i
    hours = total / 3600
    minutes = (total % 3600) / 60
    seconds = total % 60
    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  def board_total_elapsed_seconds(tickets)
    tickets.sum(&:total_elapsed_seconds)
  end

  def board_review_elapsed_seconds(tickets)
    tickets.sum(&:review_elapsed_seconds)
  end
end

