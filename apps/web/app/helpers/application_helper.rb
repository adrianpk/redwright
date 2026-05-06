module ApplicationHelper
  TICKET_MARKDOWN_TAGS = %w[
    a blockquote br code em h1 h2 h3 h4 h5 h6 hr li ol p pre strong ul
  ].freeze
  TICKET_MARKDOWN_ATTRIBUTES = %w[href title].freeze

  def ticket_markdown(text)
    html = Kramdown::Document.new(text.to_s).to_html
    sanitize(html, tags: TICKET_MARKDOWN_TAGS, attributes: TICKET_MARKDOWN_ATTRIBUTES)
  end
end
