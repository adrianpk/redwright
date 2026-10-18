require "test_helper"

class SpecificationsGeneratorTest < ActiveSupport::TestCase
  test "the wrapped harness receives project dump and quiz context and returns a draft file" do
    # Use a real subprocess boundary while keeping model/network access outside the test.
    document = create_document
    project = document.project
    use_case = create_use_case(project: project)
    dump = project.dumps.create!(title: "Billing ideas", use_case: use_case)
    dump.entries.create!(raw_input: "Allow consolidated invoices")
    quiz = use_case.find_or_create_quiz!
    quiz.entries.create!(question: "Which currency?", answer: "USD only", status: "answered")
    program = Pathname.new(project.root_path).join("test-harness")
    program.write(<<~'SCRIPT')
      #!/usr/bin/env ruby
      require "json"
      context = JSON.parse(STDIN.read.split("Context:\n", 2).last)
      raise "missing dump" unless context["dumps"].first["entries"].first["raw_input"].include?("consolidated")
      raise "missing decision" unless context["quiz_answers"].first["answer"] == "USD only"
      path = ARGV[ARGV.index("--output-last-message") + 1]
      File.write(path, JSON.generate({title: "Consolidated invoices", body: "# Invoice behavior\n\nUSD invoices only."}))
    SCRIPT
    program.chmod(0o700)
    harness = Specifications::Harness.new(program: program.to_s)
    generated = Specifications::Generator.new(project: project, use_case: use_case, harness: harness).call
    assert_equal "draft", generated.status
    assert_equal use_case.id, generated.use_case_id
    assert_includes generated.body, "USD invoices only"
    assert_match %r{\Aops/default/spec/\d{5}-consolidated-invoices/artifact.md\z}, generated.relative_path
    metadata = generated.source[:metadata]
    assert_equal "wrapped_harness", metadata["generation_source"]
    assert metadata["source_request_id"].present?
    generated.approve!(revision: generated.source_hash)
    assert_equal metadata["source_response_id"], generated.source[:metadata]["source_response_id"]
  end

  test "generation failures do not manufacture a draft" do
    document = create_document
    harness = Specifications::Harness.new(program: "/bin/false")
    assert_no_difference "Document.count" do
      assert_raises(Specifications::Error) { Specifications::Generator.new(project: document.project, harness: harness).call }
    end
  end

  test "a harness deadline leaves no partially generated specification" do
    document = create_document
    program = Pathname.new(document.project.root_path).join("slow-test-harness")
    program.write("#!/usr/bin/env ruby\nsleep 30\n")
    program.chmod(0o700)
    harness = Specifications::Harness.new(program: program.to_s, timeout: 0.05)
    assert_no_difference "Document.count" do
      error = assert_raises(Specifications::Error) { Specifications::Generator.new(project: document.project, harness: harness).call }
      assert_includes error.message, "timed out"
    end
  end

  test "quiz discovery supports no dump and isolates use cases and projects" do
    document = create_document
    project = document.project
    use_case = create_use_case(project: project)
    foreign = create_use_case(project: project, name: "Unrelated")
    project.dumps.create!(title: "Unrelated notes", use_case: foreign, raw_body: "Do not inject")
    context = Specifications::ContextBuilder.new(project: project, use_case: use_case).to_h
    assert_empty context.fetch("dumps")
    assert_empty context.fetch("quiz_answers")
    assert_equal use_case.slug, context.fetch("use_case").fetch("slug")
  end
end
