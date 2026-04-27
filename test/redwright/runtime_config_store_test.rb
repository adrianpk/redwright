# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/runtime_config_store"

class RuntimeConfigStoreTest < Minitest::Test
  def test_get_and_set_blocked_retry_attempts
    Dir.mktmpdir("redwright-config-store-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::RuntimeConfigStore.new(bootstrap.db_path)

        assert_equal(1, store.blocked_retry_attempts)
        assert_equal(3, store.set_blocked_retry_attempts(3))
        assert_equal(3, store.blocked_retry_attempts)
      end
    end
  end

  def test_set_rejects_invalid_value
    Dir.mktmpdir("redwright-config-invalid-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::RuntimeConfigStore.new(bootstrap.db_path)

        err = assert_raises(ArgumentError) { store.set_blocked_retry_attempts(0) }
        assert_match("must be >= 1", err.message)
      end
    end
  end
end
