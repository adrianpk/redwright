# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"

class ProjectStoreTest < Minitest::Test
  def test_register_and_resolve_by_alias_and_last_active
    Dir.mktmpdir("redwright-store-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::ProjectStore.new(bootstrap.db_path)

        first = store.register(path: "#{dir}/apps/alpha", aliases: ["rw", "alpha"])
        second = store.register(path: "#{dir}/apps/beta", aliases: ["beta"])

        by_alias = store.resolve("rw")
        assert_equal(first.id, by_alias.id)

        last_active = store.resolve(nil)
        assert_equal(second.id, last_active.id)

        by_path = store.resolve("#{dir}/apps/alpha")
        assert_equal(first.id, by_path.id)
      end
    end
  end
end
