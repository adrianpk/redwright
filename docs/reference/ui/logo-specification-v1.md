# RedWright Logo Specification v1

## Status
Normative specification.

This document defines the canonical RedWright logo (the full mark from `redwright.png`) and how it must be used.

---

## Canonical Asset
- Source file in web app: `apps/web/public/logo.png`
- This file is the implementation reference for login and other approved brand surfaces.

---

## Logo Composition
The logo is a stacked lockup with three layers:

1. Main character block
- Vintage craftsman illustration.
- Red cap, navy linework, tool-in-hand pose.

2. Wordmark block
- `REDWRIGHT` in large serif display style.
- Color split:
  - `RED` in brand red family.
  - `WRIGHT` in brand navy family.

3. Signature line block
- Supporting line below wordmark in heritage style.
- Includes decorative separators and centered emblem.

---

## Structural Rules
1. The three layers shall remain together as one lockup in standard usage.
2. Relative ordering shall not change:
- Character on top,
- Wordmark in the middle,
- Signature line at bottom.
3. Aspect ratio shall be preserved.
4. Character head, cap, wrench, and wordmark edges shall never be cropped.

---

## Color Rules
- Background preference: cream (`#F4EFE6`) or visually compatible light neutral.
- Red elements must remain in brand red family (`#B23A2F` / darker tonal variants).
- Blue elements must remain in brand navy family (`#1F2A44` / tonal variants).
- Do not convert to monochrome in primary UI surfaces unless an explicit monochrome variant is defined.

---

## Clear Space and Minimum Size
## Clear Space
- Maintain outer breathing room on all sides.
- Minimum clear space = height of uppercase `R` stem from the wordmark block.

## Minimum Size
- Must remain readable without zoom.
- In auth UI usage, rendered width should generally stay between `180px` and `260px` on desktop-equivalent layouts.

---

## Placement Rules
1. Authentication page
- Place above sign-in form.
- Center horizontally in auth card.

2. Operational board canvas
- Do not place full logo lockup inside dense work surfaces.
- Use typography/palette identity instead.

3. Documentation and brand sections
- Full lockup allowed as illustrative reference.

---

## Prohibited Usage
1. Distorting width/height independently.
2. Reordering composition layers.
3. Recoloring individual parts outside brand palette logic.
4. Applying heavy glow, bevel, or drop-shadow effects that alter intended tone.
5. Cropping character or wordmark edges in normal usage.

---

## Relationship to Other Brand Marks
- Favicon is a separate mark (`R/W` monogram), defined in `brand-system-v1.md`.
- This document governs only the full logo lockup.

---

## Governance
- Any modification to logo composition requires:
  - updating this spec,
  - updating canonical asset,
  - documenting rationale in the same slice.
