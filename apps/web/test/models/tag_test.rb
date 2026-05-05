require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "normalizes names to lowercase kebab case" do
    tag = Tag.create!(name: " Billing Rules ")

    assert_equal "billing-rules", tag.name
  end

  test "reuses normalized names" do
    tag = Tag.find_or_create_normalized!("Billing Rules")
    duplicate = Tag.find_or_create_normalized!("billing-rules")

    assert_equal tag, duplicate
  end

  test "rejects blank normalized names" do
    tag = Tag.new(name: "!!!")

    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end
end
