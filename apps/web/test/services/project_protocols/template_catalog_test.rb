require "test_helper"

module ProjectProtocols
  class TemplateCatalogTest < ActiveSupport::TestCase
    test "seeds common and stack templates into Rails persistence" do
      catalog = TemplateCatalog.new

      templates = catalog.all_templates

      assert ProjectProtocolTemplate.exists?(template_kind: "common", key: "common")
      assert ProjectProtocolTemplate.exists?(template_kind: "stack", key: "rails")
      common = templates.find { |template| template.template_kind == "common" }
      assert_equal "Common Protocol Template", common.name
      assert_equal "AGENTS.md", common.documents.first.path
    end

    test "seeds ruby stack template from stack protocol markdown source" do
      catalog = TemplateCatalog.new

      ruby_template = catalog.all_templates.find { |template| template.template_kind == "stack" && template.key == "ruby" }

      assert_equal "Ruby Protocol Template", ruby_template.name
      assert_equal ["architecture", "conventions", "documenting", "linting"], ruby_template.documents.order(:position).pluck(:key)
      assert_match(/Ruby repository structure/, ruby_template.documents.find_by!(key: "architecture").body)
      refute_match(/RedWright/, ruby_template.documents.map(&:body).join("\n"))
    end

    test "seeds go stack template from stack protocol markdown source" do
      catalog = TemplateCatalog.new

      go_template = catalog.all_templates.find { |template| template.template_kind == "stack" && template.key == "go" }

      assert_equal "Go Protocol Template", go_template.name
      assert_equal ["architecture", "conventions", "documenting", "linting"], go_template.documents.order(:position).pluck(:key)
      assert_match(/Go repository structure/, go_template.documents.find_by!(key: "architecture").body)
      refute_match(/Warden|RedWright/, go_template.documents.map(&:body).join("\n"))
    end

    test "seeds rails stack template from stack protocol markdown source" do
      catalog = TemplateCatalog.new

      rails_template = catalog.all_templates.find { |template| template.template_kind == "stack" && template.key == "rails" }

      assert_equal "Rails Protocol Template", rails_template.name
      assert_equal ["architecture", "conventions", "documenting", "linting"], rails_template.documents.order(:position).pluck(:key)
      assert_match(/Rails repository structure/, rails_template.documents.find_by!(key: "architecture").body)
      refute_match(/RedWright/, rails_template.documents.map(&:body).join("\n"))
    end

    test "edited templates affect future composition without rewriting existing project protocol copies" do
      catalog = TemplateCatalog.new
      rails_template = catalog.all_templates.find { |template| template.key == "rails" && template.template_kind == "stack" }
      architecture_template = rails_template.documents.find_by!(key: "architecture")
      architecture_template.update!(body: "# Rails Architecture\n\nCustomized from Rails admin.")

      existing_project = create_project(name: "Existing Rails", key: "existing-rails")
      create_project_protocol(
        project: existing_project,
        documents: [{key: "architecture", path: ".agents/ARCHITECTURE.md", title: "Architecture", layer: "stack", body: "# Existing Copy"}]
      )

      project = create_project(name: "Future Rails", key: "future-rails")
      write_setup_attribute(project, "language_runtime", "Ruby 3.4", 5)
      write_setup_attribute(project, "framework", "Rails", 4)

      composition = Composer.new(project: project).call

      architecture = composition.documents.find { |document| document.fetch("key") == "architecture" }
      assert_match(/Customized from Rails admin/, architecture.fetch("body"))
      assert_equal "# Existing Copy", existing_project.reload.protocol.documents.find_by!(key: "architecture").body
    end

    private

    def write_setup_attribute(project, slot, value, weight)
      ProjectAttribute.create!(
        project: project,
        key: "setup_context.#{slot}",
        value: value,
        weight: weight,
        source: "project_setup"
      )
    end
  end
end
