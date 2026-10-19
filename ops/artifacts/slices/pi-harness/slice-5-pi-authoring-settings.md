# Slice 5: Selectable Pi Authoring in the Web App

Status: reviewing
Delivery set: pi-harness
Plan: [Pi Harness plan](../../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
Tracker: [Pi Harness tracker](../../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
Branch: `fix/slice-5-pi-pi-authoring-settings`
PR: [#14](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/14)

## Purpose

Use prepared project profiles for existing Rails authoring actions and expose
configured selections, local readiness and active bindings through a compact
authenticated Harness page.

## Delivered Behavior

- Specifications, slicing, dump curation and protocol references use the shared
  selection/admission authority. Each action lazily admits one retained binding
  and owned lease when its first model call starts. Nested reference calls keep
  that binding and one absolute deadline after defaults change.
- Existing prompts, host schemas, semantic checks, revision conflicts, file
  locks and publication owners remain in their feature services. Generated
  specifications remain drafts. Completion is recorded after publication
  returns; rejection fails the operation, while uncertain finalization retains
  capacity and does not repeat inference.
- Null selections keep the existing Codex-compatible executable overrides.
  Explicit unavailable selections fail without fallback. Body-only protocol
  edits invoke no harness and continue when a configured profile is unavailable.
- Authenticated users configure authoring and ticket-proposal defaults with
  separate profile-key controls at the project Harness resource. An explicit
  clear restores the role default. Coherent revisions and exact retry receipts
  reject stale requests and conflicting reuse of request identities.
- The page distinguishes saved defaults from active bindings and local
  availability from provider authentication. It exposes requested provider/model
  labels without private paths, resource references, credential bytes or owner
  tokens. Rendering and selection changes make no executable/provider calls.
- Prepared-profile readiness errors remain visible. The controls use the
  existing visual language and fit both narrow and desktop viewports.

## Implementation Notes

`Harnesses::Authoring` owns lazy admission, one authoring attempt, the shared
deadline and finalization. `Specifications::Harness` creates a bound copy of
the existing feature-specific facade. `ProjectProtocols::Documents` scopes a
copy to each action so multi-call batches keep one operation without mutable
global selection state. Project-backed file stores retain the project owner;
standalone file-store use keeps its existing behavior.

Retained Pi bindings now accept the containment policy identity supplied by the
prepared profile. Private binding resources remain in the existing protected
store. Legacy executable overrides are resolved at admission, while explicit
profiles retain their own executable authority. No database transaction remains
open for inference in the ordinary Rails action path.

`Harnesses::Settings` delegates mutations to `Selection` and provides a bounded
safe snapshot. Its controller accepts only prepared keys, revision and request
metadata. Catalog readiness performs local file/platform checks without reading
credential contents or invoking an executable. The page is available from
project navigation and the project overview.

## Contracts Added or Changed

- Added the `rails-authoring/v1` operation policy for the four existing authoring
  consumers, including nested protocol reference calls.
- Added project-scoped Harness show/update routes, independent role forms,
  safe readiness catalog and active binding inspection.
- Preserved default Codex authoring and the distinct null ticket-proposal direct
  API identity. Ticket proposal consumption retains its approved Slice 6 owner.
- PI-02, PI-03, PI-04, PI-08, PI-10 and PI-15 have evidence at the authoring and
  authenticated selection boundaries.

## Files of Interest

- `apps/web/app/services/harnesses/authoring.rb`: retained binding, lease,
  deadline, publication outcome and uncertainty handling.
- `apps/web/app/services/specifications/generator.rb`, `slicing.rb`,
  `dumps/documents.rb` and `project_protocols/documents.rb`: unchanged domain/file
  authority connected to selected authoring.
- `apps/web/app/services/harnesses/settings.rb`, `profile_registry.rb` and
  `app/controllers/project_harness_settings_controller.rb`: safe snapshots,
  local readiness and coherent authenticated changes.
- `apps/web/app/views/project_harness_settings/show.html.erb`: compact role
  controls, readiness and active bindings.
- `apps/web/test/services/harnesses/authoring_integration_test.rb`: all four
  consumer boundaries, retained nested binding, rejection and uncertainty.
- `apps/web/test/controllers/project_harness_settings_controller_test.rb` and
  `test/support/harness_viewport_fixture.mjs`: HTTP/process authority and owned
  Chromium rendering against compiled styles.

## Validation

Development checks passed from the repository root:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test test/controllers/project_harness_settings_controller_test.rb test/services/harnesses/authoring_integration_test.rb test/controllers/documents_controller_test.rb test/controllers/project_protocols_controller_test.rb)
(cd apps/web && bundle exec rails dartsass:build)
(cd apps/web && RAILS_ENV=test REDWRIGHT_HARNESS_VIEWPORT=1 bundle exec rails test test/controllers/project_harness_settings_controller_test.rb -i /the_page_exposes/)
(cd apps/web && RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb)
```

Focused suite: 37 tests, 484 assertions, no failures, errors or skips; 9.54 seconds.
Viewport check: 1 test, 26 assertions; both 390- and 1280-pixel views have no
horizontal overflow, labeled controls and the expected one-/two-column layout.
Compiled colors and the shared content width are verified in the browser.
Real Pi acceptance: 5 tests, 65 assertions, no failures, errors or skips;
8.88 seconds. The added case selects Pi and generates a Rails draft through the
production consumer, native contained transport and existing file store.

Separate authenticated Rails processes use an owned SQLite database to prove
selection visibility without restart. Recording adapters isolate the external
result boundary in domain tests; native Pi uses an owned loopback endpoint and
dummy credentials. Test harness state and browser profiles are private temporary
fixtures, cleaned after their checks. No preview database or service is changed.

The first final Rails candidate at `d11c9e716b423c690ec64c97210d5bc66727e334`
had one navigation assertion failure among 608 tests: its expected menu omitted
the new Harness link. Navigation coverage now includes the link in order and
verifies its active section. Final evidence is regenerated after this correction.
The focused correction passed with 1 test and 20 assertions:
`(cd apps/web && RAILS_ENV=test bundle exec rails test test/controllers/use_cases_controller_test.rb -i /top_navigation_preserves/)`.

Final clean-HEAD checks run through `looper validate`; its retained exact-commit
evidence is authoritative before PR readiness and integration:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test)
(cd apps/web && RAILS_ENV=test bundle exec rails dartsass:build)
(cd apps/web && RAILS_ENV=test REDWRIGHT_HARNESS_VIEWPORT=1 bundle exec rails test test/controllers/project_harness_settings_controller_test.rb -i /the_page_exposes/)
(cd apps/web && RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb)
scripts/agent/tickets/check.sh
git diff --name-only --diff-filter=ACMR origin/dev...HEAD -- '*.rb' | xargs -r -n 1 ruby -wc
git diff --check
```

## Risks and Follow-ups

Readiness establishes local availability, not successful provider authentication.
The transport retains the supported native Linux containment boundary. The
ticket-proposal consumer and final integrated/operator journey keep their
approved later slices. Uncertain operations retain capacity until owned
reconciliation; the page reports their state without releasing another call.
