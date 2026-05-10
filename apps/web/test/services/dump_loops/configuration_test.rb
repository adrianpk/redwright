require "test_helper"

module DumpLoops
  class ConfigurationTest < ActiveSupport::TestCase
    test "loads defaults from yaml-backed config" do
      config = Configuration.current

      assert_equal 5, config.max_tags
      assert_equal 8, config.max_context_dumps
      assert_equal 20_000, config.max_context_dump_bytes
      assert config.entry_polishing_enabled?
      assert config.curation_enabled?
    end

    test "falls back to defaults for invalid values" do
      config = Configuration.new(
        "max_tags" => 0,
        "max_context_dumps" => "",
        "max_context_dump_bytes" => -1,
        "entry_polishing_enabled" => "false",
        "curation_enabled" => nil
      )

      assert_equal 5, config.max_tags
      assert_equal 8, config.max_context_dumps
      assert_equal 20_000, config.max_context_dump_bytes
      assert config.entry_polishing_enabled?
      assert config.curation_enabled?
    end

    test "allows explicit boolean switches" do
      config = Configuration.new(
        "entry_polishing_enabled" => false,
        "curation_enabled" => false
      )

      assert_not config.entry_polishing_enabled?
      assert_not config.curation_enabled?
    end
  end
end
