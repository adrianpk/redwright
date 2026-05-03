require "test_helper"

class ProjectProtocolTemplateTest < ActiveSupport::TestCase
  test "stores matchers as normalized JSON array" do
    template = ProjectProtocolTemplate.new(
      template_kind: "stack",
      key: "ruby",
      name: "Ruby Template"
    )
    template.matchers = ["ruby", "ruby", ""]

    assert template.valid?
    assert_equal ["ruby"], template.matchers
  end
end
