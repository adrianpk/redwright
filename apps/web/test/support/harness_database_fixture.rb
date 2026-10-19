module HarnessDatabaseFixture
  extend ActiveSupport::Concern

  included do
    self.use_transactional_tests = false
    setup :prepare_harness_database
    teardown :restore_harness_database
  end

  private

  def prepare_harness_database
    @harness_database_original = ActiveRecord::Base.connection_db_config.configuration_hash
    @harness_fixture_root = Dir.mktmpdir("harness-database-")
    @harness_fixture_database = File.join(@harness_fixture_root, "owned.sqlite3")
    ActiveRecord::Base.establish_connection(@harness_database_original.merge(database: @harness_fixture_database))
    verbose = ActiveRecord::Schema.verbose
    ActiveRecord::Schema.verbose = false
    load Rails.root.join("db/schema.rb")
    ActiveRecord::Base.descendants.each(&:reset_column_information)
  ensure
    ActiveRecord::Schema.verbose = verbose
  end

  def restore_harness_database
    if @harness_database_original
      ActiveRecord::Base.establish_connection(@harness_database_original)
      ActiveRecord::Base.descendants.each(&:reset_column_information)
    end
    FileUtils.remove_entry(@harness_fixture_root) if @harness_fixture_root && File.directory?(@harness_fixture_root)
  end
end
