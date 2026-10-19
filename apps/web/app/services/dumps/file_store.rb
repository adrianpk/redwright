module Dumps
  class FileStore < Specifications::FileStore
    PATTERNS = %w[ops/*/dump/**/artifact.md ops/conv/dump/*-dump.md].freeze

    def entries
      super(patterns: PATTERNS)
    end

    def read(path)
      entry = super
      slug = entry[:metadata]["slug"]
      if slug && (!slug.is_a?(String) || !slug.match?(/\A[a-z0-9][a-z0-9-]*\z/))
        raise Specifications::Error, "Invalid dump slug in #{path}."
      end
      tags = entry[:metadata]["tags"]
      if tags && (!tags.is_a?(Array) || tags.any? { |tag| !tag.is_a?(String) })
        raise Specifications::Error, "Invalid dump tags in #{path}."
      end
      entry
    end
  end
end
