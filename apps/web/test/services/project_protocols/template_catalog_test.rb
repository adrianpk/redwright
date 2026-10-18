require "test_helper"

module ProjectProtocols
  class TemplateCatalogTest < ActiveSupport::TestCase
    # Reading the catalog must use existing files rather than seed database state.
    test "discovers template sets from directories" do
      Dir.mktmpdir("protocol-templates-") do |root|
        FileUtils.mkdir_p(File.join(root, ".agents/stacks/custom"))
        File.write(File.join(root, "AGENTS.md"), "root")
        File.write(File.join(root, ".agents/stacks/custom/NOTES.md"), "custom")
        catalog = TemplateCatalog.new(root: root)
        assert_equal ["custom"], catalog.available_stack_keys
        assert_equal ["AGENTS.md"], catalog.common_documents.map { |document| document.fetch("path") }
        assert_equal "custom", catalog.find_template("custom").documents.first.body
      end
    end

    # Editing a template changes future initialization, never an existing project.
    test "keeps template edits separate from project files" do
      project = create_project(key: "existing-copy")
      write_protocol_files(project: project, documents: [{path: "AGENTS.md", body: "project"}])
      Dir.mktmpdir("protocol-templates-") do |root|
        File.write(File.join(root, "AGENTS.md"), "template")
        catalog = TemplateCatalog.new(root: root)
        document = catalog.common_template.files.find_path("AGENTS.md")
        assert document.update(body: "new template", revision: document.revision)
        assert_equal "new template", catalog.common_documents.first.fetch("body")
        assert_equal "project", project.protocol_files.find_path("AGENTS.md").body
      end
    end

    # Directory creation must honor the same boundary as Markdown editing.
    test "rejects an escaping template directory" do
      Dir.mktmpdir("protocol-templates-") do |root|
        Dir.mktmpdir("outside-templates-") do |outside|
          File.symlink(outside, File.join(root, ".agents"))
          assert_raises(ArgumentError) { TemplateCatalog.new(root: root).create_stack_template!(stack_key: "custom") }
          refute File.exist?(File.join(outside, "stacks"))
        end
      end
    end
  end
end
