# frozen_string_literal: true

require "fileutils"

module Redwright
  PromotionResult = Struct.new(:source_path, :target_path, keyword_init: true)

  class SpecPromotion
    def initialize(base_dir: Dir.pwd)
      @base_dir = base_dir
      @drafts_dir = File.join(@base_dir, "ops", "specs", "drafts")
      @specs_dir = File.join(@base_dir, "ops", "specs", "specs")
    end

    def promote(file_name)
      raise ArgumentError, "file name is required" if file_name.nil? || file_name.strip.empty?

      source = File.join(@drafts_dir, file_name)
      raise ArgumentError, "draft spec not found: #{file_name}" unless File.file?(source)

      FileUtils.mkdir_p(@specs_dir)
      target = File.join(@specs_dir, normalized_name(file_name))
      FileUtils.cp(source, target)

      PromotionResult.new(source_path: source, target_path: target)
    end

    private

    def normalized_name(file_name)
      file_name
        .sub(/-proto-spec-draft\.md\z/, "-proto-spec.md")
        .sub(/-functional-spec\.md\z/, "-functional-spec.md")
        .sub(/-technical-spec\.md\z/, "-technical-spec.md")
    end
  end
end
