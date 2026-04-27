# frozen_string_literal: true

module Redwright
  SkillManifest = Struct.new(
    :id, :name, :description, :entrypoint, :actions, :enabled_by_default, :path,
    keyword_init: true
  )
end
