# frozen_string_literal: true

require "minitest/autorun"
require "pathname"

class ArchitectureDependencyRulesTest < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path

  FORBIDDEN = {
    "core/domain" => ["core/application", "adapters", "runtime", "apps"],
    "core/application" => ["adapters", "runtime", "apps"],
    "core/ports" => ["adapters", "runtime", "apps"],
    "core" => ["apps"]
  }.freeze

  def test_forbidden_dependency_directions
    ruby_files.each do |file|
      source_layer = layer_for(file)
      next unless source_layer

      dependencies_for(file).each do |dep|
        forbidden_targets(source_layer).each do |forbidden_prefix|
          refute dep.start_with?(forbidden_prefix),
                 "#{relative(file)} must not depend on #{dep} (forbidden target: #{forbidden_prefix})"
        end
      end
    end
  end

  private

  def ruby_files
    roots = %w[core adapters runtime apps].map { |dir| ROOT.join(dir) }
    roots.select(&:exist?).flat_map { |root| Dir[root.join("**", "*.rb").to_s] }
  end

  def layer_for(file)
    rel = relative(file)
    return "core/domain" if rel.start_with?("core/domain/")
    return "core/application" if rel.start_with?("core/application/")
    return "core/ports" if rel.start_with?("core/ports/")
    return "core" if rel.start_with?("core/")

    return "adapters" if rel.start_with?("adapters/")
    return "runtime" if rel.start_with?("runtime/")
    return "apps" if rel.start_with?("apps/")

    nil
  end

  def dependencies_for(file)
    File.read(file).scan(/^\s*require(?:_relative)?\s+["']([^"']+)["']/).flatten
  end

  def forbidden_targets(layer)
    Array(FORBIDDEN[layer])
  end

  def relative(file)
    Pathname(file).relative_path_from(ROOT).to_s
  end
end
