module Harnesses
  class Selection
    ROLES = %w[authoring ticket_proposal].freeze
    RECEIPT_LIFETIME = 7.days
    OPERATION_RETENTION = 30.days
    MAX_OPERATIONS = 1024

    def initialize(project:, registry: ProfileRegistry.new, store: BindingStore.new, clock: -> { Time.current })
      @project, @registry, @store, @clock = project, registry, store, clock
    end

    def current
      setting = ProjectHarnessSetting.find_by(project_id: @project.id)
      setting ? setting.public_state : {"project_id" => @project.id, "authoring_profile" => nil,
        "ticket_proposal_profile" => nil, "revision" => 0, "changed_by" => nil, "changed_at" => nil}
    end

    def change!(actor:, request_id:, expected_revision:, changes:)
      unless actor.is_a?(User) && actor.persisted? && User.exists?(actor.id)
        raise Error.new("An authenticated actor is required to change harness selections.", code: :unauthorized)
      end
      validate_key!(request_id)
      unless expected_revision.is_a?(Integer) && expected_revision >= 0 && changes.is_a?(Hash) && changes.any?
        raise Error.new("Supply a selection revision and explicit changes.", code: :invalid_request)
      end
      changes = changes.stringify_keys
      unless (changes.keys - %w[authoring_profile ticket_proposal_profile]).empty? &&
          changes.values.all? { |key| key.nil? || (key.is_a?(String) && ProjectHarnessSetting::PROFILE_KEY.match?(key)) }
        raise Error.new("Only prepared profile keys or an explicit clear are supported.", code: :invalid_request)
      end
      digest = CanonicalJson.digest({actor: actor.id, revision: expected_revision, changes: changes})
      # Rails' SQLite adapter begins write transactions with BEGIN IMMEDIATE.
      # The same database lock serializes selection changes and call admission.
      ApplicationRecord.transaction do
        setting = ProjectHarnessSetting.find_or_create_by!(project_id: @project.id)
        now = @clock.call
        receipts = setting.receipts.select { |item| Time.iso8601(item.fetch("expires_at")) > now }
        receipt = receipts.find { |item| item.fetch("request_id") == request_id }
        if receipt
          raise Error.new("This selection request was already used with different changes.", code: :conflict) unless receipt.fetch("digest") == digest
          next JSON.parse(CanonicalJson.dump(receipt.fetch("result")), freeze: true)
        end
        raise Error.new("The harness selection changed. Reload before saving.", code: :stale_revision) unless setting.lock_version == expected_revision
        raise Error.new("Selection retry receipts are full. Retry after an existing receipt expires.", code: :capacity) if receipts.size >= ProjectHarnessSetting::MAX_RECEIPTS
        @registry.resolve_many(changes.values.compact).each_value(&:ready!) if changes.values.compact.any?
        setting.assign_attributes(changes.merge(changed_by: actor, changed_at: now))
        result = setting.public_state.merge("revision" => setting.lock_version + 1)
        receipts << {"request_id" => request_id, "digest" => digest, "expires_at" => (now + RECEIPT_LIFETIME).iso8601(6), "result" => result}
        setting.mutation_receipts_json = CanonicalJson.dump(receipts)
        setting.save!
        JSON.parse(CanonicalJson.dump(result), freeze: true)
      end
    end

    def admit!(operation_key:, purpose:, role:, schema:, policy_revision:, workspace_revision: {}, legacy_program: nil)
      validate_key!(operation_key)
      unless HarnessOperation::PURPOSES.include?(purpose) && ROLES.include?(role) &&
          (purpose == "ticket_proposal") == (role == "ticket_proposal") &&
          policy_revision.is_a?(String) && policy_revision.bytesize.between?(1, 128) && workspace_revision.is_a?(Hash)
        raise Error.new("Invalid harness operation identity.", code: :invalid_request)
      end
      schema_bytes = CanonicalJson.dump(schema)
      workspace_bytes = CanonicalJson.dump(workspace_revision)
      if schema_bytes.bytesize > StructuredCall::MAX_SCHEMA_BYTES || workspace_bytes.bytesize > 16 * 1024
        raise Error.new("The retained harness contract is too large.", code: :invalid_request)
      end
      contract_digest = CanonicalJson.digest({schema: schema, policy_revision: policy_revision})
      ApplicationRecord.transaction do |transaction|
        existing = @project.harness_operations.find_by(operation_key: operation_key)
        if existing
          unless existing.purpose == purpose && existing.role == role && existing.contract_digest == contract_digest && existing.workspace_revision_json == workspace_bytes
            raise Error.new("The retained operation has a different contract or workspace base.", code: :conflict)
          end
          verify_binding!(existing)
          next existing
        end
        prune_operations!(transaction)
        raise Error.new("Retained harness operations are full. Release old terminal references before retrying.", code: :capacity) if @project.harness_operations.count >= MAX_OPERATIONS
        setting = ProjectHarnessSetting.find_by(project_id: @project.id)
        profile_key = setting&.public_send("#{role}_profile")
        public_values, private_values = resolve_profile(profile_key, purpose, legacy_program: legacy_program)
        reference = @store.write(private_values)
        transaction.after_rollback { @store.delete(reference) }
        binding = public_values.merge("schema_version" => "harness-binding/v1", "operation_id" => operation_key,
          "purpose" => purpose, "role" => role, "project_ref" => @project.id.to_s,
          "workspace_ref" => CanonicalJson.digest(@project.root_path), "schema_digest" => Digest::SHA256.hexdigest(schema_bytes),
          "policy_revision" => policy_revision, "selection_revision" => setting&.lock_version || 0,
          "selection_source" => profile_key ? "prepared_profile" : "legacy_default", "profile" => profile_key)
        bytes = CanonicalJson.dump(binding)
        @project.harness_operations.create!(operation_key: operation_key, purpose: purpose, role: role,
          selection_revision: setting&.lock_version || 0, binding_json: bytes, binding_digest: Digest::SHA256.hexdigest(bytes),
          contract_digest: contract_digest, workspace_revision_json: workspace_bytes, private_run_ref: reference)
      end
    end

    private

    def validate_key!(key)
      raise Error.new("A bounded request or operation key is required.", code: :invalid_request) unless key.is_a?(String) && key.bytesize.between?(1, 128)
    end

    def verify_binding!(operation)
      unless operation.binding_valid?
        raise Error.new("Unsupported or damaged retained harness binding.", code: :invalid_binding)
      end
      @store.read(operation.private_run_ref)
    end

    def resolve_profile(key, purpose, legacy_program: nil)
      if key
        profile = @registry.resolve(key).ready!
        return [profile.public_values.except("name").merge("profile_revision" => profile.public_values.fetch("revision")), profile.private_values]
      end
      if purpose == "ticket_proposal"
        return [{"harness" => "direct_api", "profile_revision" => "legacy", "protocol_revision" => "direct-api/v1",
          "requested_provider" => nil, "requested_model" => nil, "capabilities" => {}}, {}]
      end
      program = case purpose
      when "curation" then ENV.fetch("REDWRIGHT_DUMP_HARNESS", ENV.fetch("REDWRIGHT_SPEC_HARNESS", "codex"))
      when "references" then ENV.fetch("REDWRIGHT_PROTOCOL_HARNESS", ENV.fetch("REDWRIGHT_SPEC_HARNESS", "codex"))
      else ENV.fetch("REDWRIGHT_SPEC_HARNESS", "codex")
      end
      program = legacy_program if legacy_program
      [{"harness" => "codex", "profile_revision" => CanonicalJson.digest(program), "protocol_revision" => "codex-exec/v1",
        "requested_provider" => nil, "requested_model" => nil, "capabilities" => {"structured_output" => true}}, {"executable_ref" => program}]
    end

    def prune_operations!(transaction)
      @project.harness_operations.where(state: HarnessOperation::TERMINAL_STATES).where("finished_at < ?", @clock.call - OPERATION_RETENTION).find_each do |operation|
        next if operation.referenced?
        reference = operation.private_run_ref
        operation.destroy!
        transaction.after_commit { @store.delete(reference) }
      end
    end
  end
end
