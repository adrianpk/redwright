# RedWright Brand System v1

## Status
Normative specification.

This document defines the visual identity primitives for RedWright:
- favicon monogram,
- primary logo composition,
- main character representation.

Detailed full-logo usage is specified in:
- `docs/reference/ui/logo-specification-v1.md`

---

## Brand Intent
RedWright identity shall communicate:
- crafted engineering,
- reliability,
- operational clarity,
- human-guided automation.

The tone is artisan-industrial, not playful and not corporate-generic.

---

## Core Palette
- Cream base: `#F4EFE6`
- Deep navy: `#1F2A44`
- Soft navy: `#3A4A63`
- Primary red: `#B23A2F`
- Deep red: `#8C2C24`
- Auxiliary brown accents for heritage tone: `#6F5841` family

Rules:
- Cream is the dominant ground.
- Navy is the dominant structural/text contrast.
- Red is accent, not background default.

---

## Favicon Specification
## Purpose
The favicon must remain recognizable at very small sizes and preserve RedWright identity.

## Construction
- Format: SVG primary, PNG fallback.
- Base: cream rounded square.
- Mark: monogram `R` + `W`.
- Color split:
  - `R` in brand red,
  - `W` in brand navy.

## Legibility Rules
- `R` and `W` must be visually distinct at 16px and 32px.
- Inter-letter spacing must avoid overlap/merging.
- Outer margins must be balanced left/right.
- No thin ornamental strokes that collapse at small raster sizes.

## Prohibited
- Single-color circle fallback as canonical icon.
- Over-compressed letterforms that read as one glyph.
- Non-cream background for default brand favicon.

---

## Primary Logo Specification
## Source Asset
- Canonical login/brand asset: `public/logo.png`.

## Composition
- Main character (craftsman) above wordmark.
- Wordmark with dual color emphasis:
  - `RED` in red family,
  - `WRIGHT` in navy family.
- Supporting subtitle line (artisan-software identity) may appear in long-form contexts.

## Usage Rules
- Preserve aspect ratio.
- Do not crop character head, cap, or wrench hand.
- Do not recolor independently from approved palette.
- Keep sufficient breathing room around logo.

## Minimum Readability
- In UI contexts, logo must remain readable without zoom.
- On auth surface, logo width should scale responsively and stay above form controls.

---

## Main Character Specification
## Role
The main character is a symbolic operator of the software factory.
It represents skilled execution, not mascot comedy.

## Visual Attributes
- Vintage craftsman silhouette.
- Red cap, navy linework, cream-compatible rendering.
- Tool-bearing stance (wrench) as a cue for build/repair capability.

## Behavioral Constraints in UI
- Character should appear in identity surfaces (login, brand docs, optional landing/header contexts).
- Character should not clutter dense operational surfaces (e.g., Kanban columns, ticket cards).
- Character usage must support hierarchy, not dominate workflow controls.

---

## Placement Matrix
1. Browser/Tab Identity:
- Use favicon monogram.

2. Authentication Page:
- Use full `logo.png` above sign-in form.

3. Operational Board:
- Use textual product identity and palette, avoid full character lockup in working canvas.

4. Documentation:
- Use full brand references in design/brand sections.

---

## Accessibility and Contrast
- Brand marks must maintain clear contrast on cream backgrounds.
- Red/navy combinations must avoid low-contrast overlays.
- Decorative details must never be the only carrier of identity.

---

## Versioning and Governance
- Any change to favicon geometry, monogram spacing, or logo composition requires an explicit brand-system update.
- UI specs that reference brand assets must cite this document.
