require "socket"
require "timeout"

module PiAcceptanceFixture
  class Endpoint
    def initialize(mode: :valid, payload: nil)
      @payload = payload
      @mode, @requests, @mutex = mode, [], Mutex.new
      @server = TCPServer.new("127.0.0.1", 0)
      @port = @server.addr[1]
      @workers = []
      @thread = Thread.new do
        loop do
          socket = @server.accept
          @workers << Thread.new(socket) { |client| serve(client) }
        end
      rescue IOError, Errno::EBADF
        nil
      end
    end

    def url = "http://127.0.0.1:#{@port}/v1"
    def requests = @mutex.synchronize { @requests.dup }

    def close
      @closed = true
      @server.close
      @thread.join(2) || raise("Owned endpoint did not stop")
      @workers.each { |thread| thread.join(2) || raise("Owned endpoint request did not stop") }
    end

    private

    def serve(client)
      Timeout.timeout(10) do
        first = client.gets("\r\n", 8192)
        headers = {}
        while (line = client.gets("\r\n", 8192)) && line != "\r\n"
          key, value = line.split(":", 2)
          headers[key.downcase] = value.strip
          raise "Oversized fixture headers" if headers.size > 64
        end
        length = Integer(headers.fetch("content-length"))
        raise "Oversized fixture request" unless length.between?(1, 1024 * 1024)
        body = JSON.parse(client.read(length))
        @mutex.synchronize { @requests << {path: first.split[1], headers: headers, body: body} }
        if @mode == :hang
          IO.select(nil, nil, nil, 0.02) until @closed
          return
        end
        if @mode == :provider_error
          bytes = JSON.generate(error: {message: "owned endpoint rejection", type: "server_error"})
          client.write("HTTP/1.1 503 Service Unavailable\r\nContent-Type: application/json\r\nContent-Length: #{bytes.bytesize}\r\nConnection: close\r\n\r\n#{bytes}")
          return
        end
        content = body.fetch("messages").map { |message| message["content"].to_s }.join("\n")
        tag = content.include?("request-beta") ? "beta" : "alpha"
        delta = {"role" => "assistant", "content" => JSON.generate(@payload || {title: "Bounded #{tag}", body: "Owned loopback behavior."})}
        if @mode == :tool
          delta = {"role" => "assistant", "tool_calls" => [{"index" => 0, "id" => "owned-tool", "type" => "function",
            "function" => {"name" => "bash", "arguments" => '{"command":"false"}'}}]}
        end
        client.write("HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n")
        chunk = {"id" => "owned-completion", "object" => "chat.completion.chunk", "created" => 1,
          "model" => "bounded-model", "choices" => [{"index" => 0, "delta" => delta, "finish_reason" => nil}]}
        client.write("data: #{JSON.generate(chunk)}\n\n")
        chunk["choices"] = [{"index" => 0, "delta" => {}, "finish_reason" => @mode == :tool ? "tool_calls" : "stop"}]
        chunk["usage"] = {"prompt_tokens" => 17, "completion_tokens" => 9, "total_tokens" => 26}
        client.write("data: #{JSON.generate(chunk)}\n\ndata: [DONE]\n\n")
      end
    rescue Errno::EPIPE, Errno::ECONNRESET
      nil
    ensure
      client.close
    end
  end

  class RecordingSandbox
    attr_reader :contexts

    def initialize
      @contexts = []
    end

    def with_context(request)
      Harnesses::LinuxSandbox.new.with_context(request) do |context|
        @contexts << context
        yield context
      end
    end
  end

  def native_pi
    return ENV.fetch("REDWRIGHT_PI_BINARY") if ENV.key?("REDWRIGHT_PI_BINARY")
    result = Harnesses::ProcessSupervisor.new(stdout_limit: 4096, stderr_limit: 4096).run(
      command: ["mise", "which", "pi"], workspace: Dir.tmpdir,
      deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5, capture_stdout: 4096)
    raise "The required pinned native Pi executable is unavailable" unless result.status.success?
    File.realpath(result.stdout.strip)
  end

  def acceptance_request(project, endpoint, tag: "alpha", timeout: 20, cancellation: nil)
    root = Dir.mktmpdir("pi-acceptance-resources-")
    (@protocol_test_directories ||= []) << root
    auth = File.join(root, "auth.json")
    models = File.join(root, "models.json")
    File.write(auth, JSON.generate("loopback-fixture" => {type: "api_key", key: "owned-loopback-key"},
      "unrelated-provider" => {type: "api_key", key: "unrelated-key-canary"}), perm: 0o600)
    File.write(models, JSON.generate(providers: {"loopback-fixture" => {baseUrl: endpoint.url, api: "openai-completions", authHeader: true,
      models: [{id: "bounded-model", name: "Owned loopback", reasoning: false, input: ["text"],
        cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0}, contextWindow: 32768, maxTokens: 1024}]}}), perm: 0o600)
    registry_path = File.join(root, "profiles.json")
    profile = {name: "loopback", harness: "pi", executable_ref: native_pi, protocol_revision: "1.3.0", thinking: "off",
      requested_provider: "loopback-fixture", requested_model: "bounded-model", credential_ref: auth, model_config_ref: models,
      capabilities: {structured_output: true, os_read_only_containment: true}}
    File.write(registry_path, JSON.generate(version: 1, profiles: [profile]), perm: 0o600)
    resolved = Harnesses::ProfileRegistry.new(path: registry_path).resolve("loopback").ready!
    schema = Specifications::Harness::OUTPUT_SCHEMA
    binding = resolved.public_values.merge("schema_digest" => Harnesses::CanonicalJson.digest(schema))
    request = Harnesses::Request.new(instructions: "Return a JSON title and body for request-#{tag}.", context: {source: "Owned acceptance context."},
      workspace: project.root_path, schema: schema, purpose: "specification", harness: "pi", program: profile.fetch(:executable_ref),
      binding: binding, resources: resolved.private_values, timeout: timeout, cancellation: cancellation)
    [request, root]
  end
end
