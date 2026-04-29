# frozen_string_literal: true

module Redwright
  class TemplateSourceResolver
    DEFAULT_ORDER = %w[project global builtin].freeze

    def ordered_sources(manifest)
      sources = Array(manifest&.template_sources)
      grouped = sources.group_by { |s| s["kind"].to_s }
      DEFAULT_ORDER.flat_map { |kind| Array(grouped[kind]) }
    end
  end
end
