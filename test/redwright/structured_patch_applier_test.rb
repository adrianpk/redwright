# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/structured_patch_applier"

class StructuredPatchApplierTest < Minitest::Test
  def test_applies_update_and_add_operations
    Dir.mktmpdir("redwright-structured-patch-") do |dir|
      File.write(File.join(dir, "main.go"), "package main\n\nfunc main() {}\n")

      result = Redwright::StructuredPatchApplier.new.apply(
        project_root: dir,
        patch: <<~PATCH
          *** Begin Patch
          *** Update File: main.go
          @@
           package main
          +
          +import "fmt"
          *** Add File: README.md
          +# Demo
          +
          +Created by structured patch.
          *** End Patch
        PATCH
      )

      assert_equal "applied structured patch\n", result.fetch(:stdout)
      assert_includes File.read(File.join(dir, "main.go")), 'import "fmt"'
      assert_equal "# Demo\n\nCreated by structured patch.\n", File.read(File.join(dir, "README.md"))
    end
  end

  def test_rejects_context_that_cannot_be_found
    Dir.mktmpdir("redwright-structured-patch-context-") do |dir|
      File.write(File.join(dir, "main.go"), "package main\n")

      error = assert_raises(RuntimeError) do
        Redwright::StructuredPatchApplier.new.apply(
          project_root: dir,
          patch: <<~PATCH
            *** Begin Patch
            *** Update File: main.go
            @@
            -missing
            +present
            *** End Patch
          PATCH
        )
      end

      assert_match "apply_patch_context_not_found: main.go", error.message
    end
  end

  def test_rejects_paths_outside_project_root
    Dir.mktmpdir("redwright-structured-patch-path-") do |dir|
      error = assert_raises(ArgumentError) do
        Redwright::StructuredPatchApplier.new.apply(
          project_root: dir,
          patch: <<~PATCH
            *** Begin Patch
            *** Add File: ../outside.txt
            +outside
            *** End Patch
          PATCH
        )
      end

      assert_equal "path_outside_project_root", error.message
    end
  end

  def test_rejects_existing_added_file
    Dir.mktmpdir("redwright-structured-patch-existing-") do |dir|
      File.write(File.join(dir, "README.md"), "existing\n")

      error = assert_raises(RuntimeError) do
        Redwright::StructuredPatchApplier.new.apply(
          project_root: dir,
          patch: <<~PATCH
            *** Begin Patch
            *** Add File: README.md
            +new
            *** End Patch
          PATCH
        )
      end

      assert_equal "apply_patch_file_exists: README.md", error.message
    end
  end

  def test_rejects_unsupported_delete_and_move_operations
    Dir.mktmpdir("redwright-structured-patch-unsupported-") do |dir|
      delete_error = assert_raises(RuntimeError) do
        Redwright::StructuredPatchApplier.new.apply(
          project_root: dir,
          patch: <<~PATCH
            *** Begin Patch
            *** Delete File: old.txt
            *** End Patch
          PATCH
        )
      end

      move_error = assert_raises(RuntimeError) do
        Redwright::StructuredPatchApplier.new.apply(
          project_root: dir,
          patch: <<~PATCH
            *** Begin Patch
            *** Move to: new.txt
            *** End Patch
          PATCH
        )
      end

      assert_equal "unsupported_apply_patch_operation: delete_file", delete_error.message
      assert_equal "unsupported_apply_patch_operation: move_to", move_error.message
    end
  end

  def test_detects_structured_patch_marker
    assert Redwright::StructuredPatchApplier.structured_patch?("*** Begin Patch\n*** End Patch\n")
    refute Redwright::StructuredPatchApplier.structured_patch?("diff --git a/x b/x\n")
  end
end
