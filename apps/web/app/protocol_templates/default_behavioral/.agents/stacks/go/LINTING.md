# Go Quality-Gate Overlay

Apply this overlay with `.agents/LINTING.md`. Repository-owned commands
override these generic Go examples.

## Baseline Commands

- Format the changed Go files with `gofmt`.
- Run `go test` for affected packages, with `-run` for a focused regression when
  useful. Use `go test ./...` only when the selected gate calls for all packages.
- Use `-race` for affected concurrency behavior or a required integration gate;
  do not mechanically repeat every suite with and without it.
- Batch roots in a package invocation instead of running `go test` once per
  root. Use the build cache and safe fixture reuse; justify disabling caching,
  serializing independent work, or rebuilding the same application repeatedly.

## Configured Extensions

- Use `golangci-lint run ./...`, `go vet ./...`, and project coverage commands
  only when the repository configures them.
- Prefer defect-oriented linters such as `govet`, `staticcheck`, `ineffassign`,
  `errcheck`, `unused`, `errorlint`, and context- or HTTP-specific checks when
  applicable.
- Use `gofmt`, `goimports`, or `gci` according to repository configuration.
