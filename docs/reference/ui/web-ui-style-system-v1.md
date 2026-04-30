# Web UI Style System v1

## Status
Normative specification.

This document defines global visual and interaction style rules for the RedWright web interface.
Module-specific behavior (for example Kanban board logic) belongs to module specs.
Brand primitives are defined in:
- `docs/reference/ui/brand-system-v1.md`

---

## Purpose
Provide a shared style substrate across all web surfaces:
- authentication,
- board surfaces,
- settings,
- administration.

---

## Global Design Principles
1. Clarity over ornament.
2. Consistent visual language across modules.
3. Controlled emphasis using sparse accents.
4. Progressive disclosure over persistent control noise.
5. Motion must communicate state, not decorate.

---

## Visual Tokens
## Color
- `--cream: #F4EFE6`
- `--navy: #1F2A44`
- `--navy-soft: #3A4A63`
- `--accent-red: #B23A2F`
- `--accent-red-dark: #8C2C24`
- `--border-soft: #E5DED3`
- `--muted: #6B7280`
- `--card: #FBF8F2`

## Typography
- Primary family: `"IBM Plex Sans", "Segoe UI", sans-serif`
- Heading weight: `600`
- Body weight: `400`
- Uppercase only for compact semantic chips.

## Shape
- Standard container radius: `12px`
- Card radius: `10px`
- Modal radius: `14px`
- Pill/chip radius: `999px`

## Spacing
- 4px base grid.
- Approved rhythm increments: `8 / 10 / 12 / 20 / 24`.

## Elevation
- Subtle depth for cards and panels.
- Strongest depth reserved for active modal surfaces.
- Avoid heavy shadow stacks.

## Motion
- Duration range: `120ms–160ms`.
- Easing: simple ease curves.
- No bounce/spring effects in core operational flows.

---

## Surface Rules
## Authentication Surfaces
- Must present as standalone full-page views.
- Must not appear as inline fragments within protected surfaces.
- Must use same token system as application surfaces.
- Must support brand mark placement above form content.

## Modal Surfaces
- Must preserve contextual continuity with underlying surface.
- Must include explicit close affordance.
- Must support backdrop close unless explicitly prohibited by flow.
- Header window actions shall be icon-only controls.
- Text-labeled window actions such as `Close`, `Minimize`, `Maximize` shall not be used in modal headers.
- Window controls shall be placed in the upper-right corner of the modal surface.

## Empty States
- Must look intentional and production-grade.
- Must avoid placeholder-like copy or visual defaults.

## Brand Marks and Favicon
- Favicon must use RedWright monogram (`R` and `W`) on cream background.
- Monogram colors must follow brand red/navy contrast.
- Monogram spacing must preserve distinct letter readability at small sizes.
- Login surface should display primary brand mark (`logo.png`) above auth controls.

---

## Accessibility Baseline
- Keyboard-reachable controls.
- Visible focus states.
- Non-color-only semantic cues for critical states.
- Minimum readable contrast for primary text and controls.

---

## Prohibited Patterns
1. Raw unstyled fallback blocks in normal UI paths.
2. Inconsistent token overrides per feature without explicit spec.
3. Oversized destructive affordances that dominate the viewport.
4. Full-page reload defaults for interactions that are specified as in-place.

---

## Change Protocol
- Any UI module spec must reference this style system.
- Token changes must be updated here before implementation merge.
