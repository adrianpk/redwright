# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "pathname"
require "bundler"

class RailsWebScaffoldSmokeTest < Minitest::Test
  ROOT = Pathname.new(File.expand_path("../..", __dir__))
  WEB_APP = ROOT.join("apps/web")

  def test_rails_web_scaffold_exists
    assert(WEB_APP.directory?, "expected apps/web to exist")
    assert(WEB_APP.join("config/application.rb").file?, "expected rails app config to exist")
    assert(WEB_APP.join("app/controllers/application_controller.rb").file?, "expected application controller to exist")
  end

  def test_rails_web_boot_smoke_runner
    stdout = ""
    stderr = ""
    status = nil
    Bundler.with_unbundled_env do
      stdout, stderr, status = Open3.capture3(
        { "BUNDLE_GEMFILE" => WEB_APP.join("Gemfile").to_s },
        "bundle exec ruby bin/rails runner \"puts 'rw-web-ok'\"",
        chdir: WEB_APP.to_s
      )
    end

    assert(status.success?, "expected rails runner to boot successfully\nstdout=#{stdout}\nstderr=#{stderr}")
    assert_includes(stdout, "rw-web-ok")
  end

  def test_repository_boundaries_exist
    %w[
      core/application
      core/domain
      core/ports
      adapters/ingress/telegram
      adapters/ingress/tui
      adapters/ingress/web
      adapters/egress/git
      adapters/egress/sandbox
      adapters/egress/llm
      adapters/egress/persistence
      runtime/unified
    ].each do |path|
      assert(ROOT.join(path).directory?, "expected #{path} directory to exist")
    end
  end
end
