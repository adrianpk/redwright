# Chrome Extension Overlay

Apply this language-independent Manifest V3 overlay with the global contracts
and every detected language overlay.

## Runtime boundaries

- Keep the Manifest V3 service worker, content scripts, extension pages, and
  product logic in separate modules or packages.
- Keep page DOM extraction and in-page UI insertion behind content-script
  adapters. Keep policy, matching, analysis, and rule evaluation independent
  of browser APIs and page-specific selectors.
- Treat page DOM structures as untrusted and volatile. Parse defensively and
  keep selector changes local to the relevant adapter.
- Use a Shadow DOM root for extension-owned in-page controls and panels unless
  the target site or product requirements need another isolation strategy.

## Manifest and security

- Use Manifest V3 and keep permissions and host permissions to the minimum
  needed for implemented behavior.
- Do not load executable remote code, use `eval`, or weaken extension content
  security policy.
- Keep extension pages, content scripts, and the service worker explicit
  manifest entrypoints.
- Keep browser API access behind narrow adapters so domain behavior remains
  testable without a browser runtime.

## Storage and external communication

- Use local browser storage by default. Add synchronization or remote services
  only after an explicit product decision.
- Document all persisted data and validate it at the storage boundary.
- Do not send page content, browsing data, user configuration, or credentials
  to external services unless the product explicitly requires it and the user
  can understand and control that transfer.

## Testing and validation

- Unit-test policy, matching, parsing, and persistence behavior without
  browser APIs.
- Test content-script adapters with representative DOM fixtures; do not make
  live third-party pages a required test dependency.
- Configure a production extension build and validate the resulting manifest,
  type or compile checks for the chosen language, and the automated test suite.
