module ProtocolReferenceHarnessFixture
  def protocol_reference_harness(root)
    path = Pathname.new(root).join("reference-harness")
    path.write(<<~'RUBY')
      #!/usr/bin/env ruby
      require "json"
      prompt = STDIN.read
      raise "wrong task" unless prompt.include?("Update references in the supplied AGENTS.md")
      context = JSON.parse(prompt.split("Context:\n", 2).last)
      body = context.fetch("agents_body")
      old_path = context["old_path"] || context["path"]
      body = body.lines.reject { |line| line.include?("`#{old_path}`") }.join
      unless context.fetch("operation") == "delete"
        description = context.fetch("description")
        body = body.rstrip + "\n\n- `#{context.fetch('path')}`"
        body += " — #{description}" unless description.empty?
        body += "\n"
      end
      File.write(ARGV[ARGV.index("--output-last-message") + 1], JSON.generate({body: body}))
    RUBY
    path.chmod(0o700)
    path.to_s
  end
end
