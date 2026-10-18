# Go Documentation Overlay

Apply this overlay with `.agents/DOCUMENTING.md` and `.agents/LANGUAGE.md`.

- Keep commands aligned with actual Go entrypoints and package roots, such as
  `go run ./cmd/...`, `go build ./...`, and `go test ./...`.
- Use exact Go import paths, package names, exported identifiers, signatures,
  structs, interfaces, and error contracts.
- Add useful Godoc to exported APIs that form a caller-visible contract.
- Keep generated or embedded asset documentation close to its owning package
  unless it is a user-facing reference contract.
