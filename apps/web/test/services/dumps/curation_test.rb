require "test_helper"

class DumpCurationTest < ActiveSupport::TestCase
  test "the wrapped harness polishes the same file without changing its status" do
    project = create_project
    dump = project.dumps.create!(body: "rouhg notes", status: "ready")
    path = dump.relative_path
    program = Pathname.new(project.root_path).join("polish-harness")
    program.write(<<~'RUBY')
      #!/usr/bin/env ruby
      require "json"
      prompt = STDIN.read
      raise "wrong task" unless prompt.include?("Curate the supplied dump Markdown")
      context = JSON.parse(prompt.split("Context:\n", 2).last)
      raise "missing document" unless context.fetch("dump").fetch("body") == "rouhg notes"
      File.write(ARGV[ARGV.index("--output-last-message") + 1], JSON.generate({title: context["dump"]["title"], body: "Rough notes."}))
    RUBY
    program.chmod(0o700)
    Dumps::Documents.new(project).curate(dump, revision: dump.source_hash, harness: Dumps::Harness.new(program: program.to_s))
    assert_equal path, dump.relative_path
    assert_equal "Rough notes.", dump.body
    assert_equal "ready", dump.status
    assert_equal 1, project.dumps.count
  end

  test "harness failures and concurrent file edits preserve the document" do
    project = create_project
    dump = project.dumps.create!(body: "Original")
    service = Dumps::Documents.new(project)
    assert_raises(Specifications::Error) { service.curate(dump, revision: dump.source_hash, harness: Dumps::Harness.new(program: "/bin/false")) }
    assert_equal "Original", dump.source[:body]
    revision = dump.source_hash
    harness = Object.new
    harness.define_singleton_method(:generate) do |**|
      current = Dump.find(dump.id)
      current.update!(body: "External edit")
      {"title" => dump.title, "body" => "Polished old text"}
    end
    error = assert_raises(Specifications::Error) { service.curate(dump, revision: revision, harness: harness) }
    assert_equal :conflict, error.code
    assert_equal "External edit", dump.source[:body]
  end
end
