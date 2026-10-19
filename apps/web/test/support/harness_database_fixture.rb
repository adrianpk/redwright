require "timeout"

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

  def harness_processes(count, &action)
    # Each child opens its own SQLite connection; pipes align the competing writes.
    ActiveRecord::Base.connection_pool.disconnect!
    children = []
    count.times do |index|
      gate_read, gate_write = IO.pipe
      result_read, result_write = IO.pipe
      pid = fork do
        gate_write.close
        result_read.close
        begin
          ActiveRecord::Base.establish_connection(@harness_database_original.merge(database: @harness_fixture_database))
          result_write.puts("ready")
          result_write.flush
          gate_read.read(1)
          value = action.call(index)
          result_write.write(JSON.generate({"ok" => true, "value" => value}))
        rescue Harnesses::Error => error
          result_write.write(JSON.generate({"ok" => false, "code" => error.code.to_s}))
        rescue StandardError => error
          result_write.write(JSON.generate({"exception" => error.class.name, "message" => error.message}))
        ensure
          result_write.close
          exit! 0
        end
      end
      gate_read.close
      result_write.close
      children << {pid: pid, gate: gate_write, result: result_read}
    end
    Timeout.timeout(20) do
      children.each { |child| assert_equal "ready\n", child[:result].gets }
      children.each { |child| child[:gate].write("g"); child[:gate].close }
      children.map do |child|
        result = JSON.parse(child[:result].read(64 * 1024))
        _, status = Process.wait2(child[:pid])
        assert status.success?
        assert_nil result["exception"], result["message"]
        result
      end
    end
  ensure
    Array(children).each do |child|
      begin
        if Process.waitpid(child[:pid], Process::WNOHANG).nil?
          Process.kill("KILL", child[:pid])
          Process.wait(child[:pid])
        end
      rescue Errno::ECHILD, Errno::ESRCH
        # Successful children were already reaped above.
      end
      child[:gate].close unless child[:gate].closed?
      child[:result].close unless child[:result].closed?
    end
  end
end
