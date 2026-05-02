require "test_helper"

module ProjectInitialization
  class RepositoryResolverTest < ActiveSupport::TestCase
    test "resolves explicit repository url" do
      resolution = RepositoryResolver.new(input: "git@codeberg.org:acme/inventory-service.git").call

      assert_equal :resolved, resolution[:status]
      assert_equal "git@codeberg.org:acme/inventory-service.git", resolution[:repository][:canonical]
      assert_equal :explicit_url, resolution[:repository][:source]
    end

    test "resolves owner repository identifier" do
      resolution = RepositoryResolver.new(input: "acme/inventory-service").call

      assert_equal :resolved, resolution[:status]
      assert_equal "https://github.com/acme/inventory-service.git", resolution[:repository][:canonical]
      assert_equal :owner_repo, resolution[:repository][:source]
    end

    test "returns ambiguous when repository input is incomplete" do
      resolution = RepositoryResolver.new(input: "inventory-service").call

      assert_equal :ambiguous, resolution[:status]
      assert_equal :unsupported_or_incomplete_repository_identifier, resolution[:clarification][:reason]
      assert_equal "inventory-service", resolution[:clarification][:original_input]
      assert_includes resolution[:clarification][:expected_formats], "owner/repository"
    end

    test "returns cancelled for cancellation intent" do
      resolution = RepositoryResolver.new(input: "/cancel").call

      assert_equal :cancelled, resolution[:status]
    end
  end
end
